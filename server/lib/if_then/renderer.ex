defmodule IfThen.Renderer do
  use GenServer

  require Logger

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
    |> IO.inspect(label: "x")

    :timer.send_interval(@increment, :tick)
    {:ok, %State{t: 0, tokens: tokens}}
  end

  def handle_call({:input, message}, _from, state) do
    state = handle_input(message, state)
    IO.inspect Map.take(state, [:speed, :volume, :pitch]), label: "X"

    {:reply, :ok, state}
  end

  def handle_info(:tick, state = %State{tokens: []}) do
    {:stop, :normal, state}
  end

  def handle_info(:tick, state = %State{tokens: [ [word, time] | rest]}) do
    state = %State{state | t: state.t + ((1 + state.speed) * @increment)}
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
      "word" => List.first(state.tokens) |> List.first}
    |> Poison.encode!()
    |> send_direct("192.168.1.90")
  end
  def send_direct(message, addr) do
    {:ok, socket} = :gen_udp.open(0, [:binary])
    Logger.debug "Send to #{inspect addr}: #{message}"
    :gen_udp.send(socket, String.to_char_list(addr), 5000, message)
    :gen_udp.close(socket)
  end

  @min_heart_rate 60
  @max_heart_rate 180

  defp handle_input(message, state) do
    state
    |> handle_metric(message["speed"], fn(v, state) -> %State{state | speed: v} end)
    |> handle_metric(message["volume"], fn(v, state) -> %State{state | volume: v} end)
    |> handle_metric(message["pitch"], fn(v, state) -> %State{state | pitch: v} end)

    |> handle_metric(message["HeartBPM"], fn(v, state) ->
      s = (v - @min_heart_rate) / (@max_heart_rate - @min_heart_rate)
      %State{state | volume: 1 + s}
    end)
  end

  defp handle_metric(state, v, callback) when is_number(v) do
    callback.(v, state)
  end
  defp handle_metric(state, _value, _callback) do
    state
  end

end
