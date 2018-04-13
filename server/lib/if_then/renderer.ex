defmodule IfThen.Renderer do
  use GenServer

  require Logger

  alias IfThen.Calibration

  @ip Application.fetch_env!(:if_then, :unity_ip)

  def start_link(id) do
    GenServer.start_link(__MODULE__, [id], name: __MODULE__)
  end

  def active? do
    Process.whereis(__MODULE__) != nil
  end

  def input(message) do
    GenServer.call(__MODULE__, {:input, message})
  end

  @increment 100

  defmodule State do
    defstruct [
      t: 0,
      base_values: %{},
      speed: 1,
      volume: 1,
      pitch: 1,
      tokens: []
    ]
  end

  def init([id]) do
    tokens = File.read!(id <> ".json")
    |> Poison.decode!()
    |> Enum.map(fn([word, time]) -> [word, time * 1000] end)

    base_values = %{
      :GSR1 => Calibration.average(:GSR1),
      :GSR2 => Calibration.average(:GSR2),
      :HeartBPM => Calibration.average(:HeartBPM)
    }

    :timer.send_interval(@increment, :tick)
    {:ok, %State{t: 0, tokens: tokens, base_values: base_values}}
  end

  def handle_call({:input, message}, _from, state) do
    state = handle_input(message, state)
    {:reply, :ok, state}
  end

  def handle_info(:tick, state = %State{tokens: []}) do
    Logger.warn("- stop -")
    send_stop_udp()
    Phoenix.PubSub.broadcast(IfThen.PubSub, "audio", %Phoenix.Socket.Broadcast{event: "done", payload: %{}})
    {:stop, :normal, state}
  end

  def handle_info(:tick, state = %State{tokens: [ [word, time] | rest]}) do
    state = %State{state | t: state.t + ((2 * state.speed) * @increment)}
    send_udp(state)
    if time < state.t do
      Phoenix.PubSub.broadcast(IfThen.PubSub, "audio", %Phoenix.Socket.Broadcast{event: "word", payload: word_payload(word, state)})
      {:noreply, %State{state | tokens: rest}}
    else
      {:noreply, state}
    end
  end

  defp word_payload(word, state) do
    %{"word" => word,
      "speed" => state.speed,
      "volume" => state.volume,
      "pitch" => state.pitch
    }
  end

  def send_udp(state) do
    %{"timecode" => state.t / 1000,
      "volume" => state.volume,
      "pitch" => state.pitch,
      "speed" => state.speed,
      "word" => List.first(state.tokens) |> List.first}
    |> Poison.encode!()
    |> send_direct(@ip)
  end
  def send_direct(message, addr) do
    {:ok, socket} = :gen_udp.open(0, [:binary])
    Logger.debug "Send to #{inspect addr}: #{message}"
    :gen_udp.send(socket, String.to_char_list(addr), 5000, message)
    :gen_udp.close(socket)
  end

  def send_stop_udp() do
    %{"timecode" => -1}
    |> Poison.encode!()
    |> send_direct(@ip)
  end

  @heart_max_delta 15
  @gsr_max_delta 150

  defp handle_input(message, state) do
    state
    |> handle_metric(message["speed"], fn(v, state) -> %State{state | speed: v} end)
    |> handle_metric(message["volume"], fn(v, state) -> %State{state | volume: v} end)
    |> handle_metric(message["pitch"], fn(v, state) -> %State{state | pitch: v} end)

    |> handle_metric(message["HeartBPM"], fn(v, state) ->
      # %State{state | speed: 0.5}
      %State{state | speed: window(v, state.base_values[:HeartBPM], @heart_max_delta)}
    end)
    |> handle_metric(message["GSR1"], fn(v, state) ->
      %State{state | volume: 1 - window(v, state.base_values[:GSR1], @gsr_max_delta)}
    end)
    |> handle_metric(message["GSR2"], fn(v, state) ->
      %State{state | pitch: 1 - window(v, state.base_values[:GSR2], @gsr_max_delta)}
    end)
  end

  defp window(value, base, delta) do
    (0.5 + 0.5 * (value - base) / delta)
    |> max(0) |> min(1)
  end

  defp handle_metric(state, v, callback) when is_number(v) do
    callback.(v, state)
  end
  defp handle_metric(state, _value, _callback) do
    state
  end

end
