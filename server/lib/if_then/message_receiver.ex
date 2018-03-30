defmodule IfThen.MessageReceiver do
  use GenServer

  require Logger
  alias IfThen.{Calibration, Renderer}

  defmodule State do
    defstruct socket: nil
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, socket} = :gen_udp.open(33333, [:binary, {:active, :once}])
    {:ok, %State{socket: socket}}
  end

  def handle_info({:udp, socket, host, _port, "{" <> _ = msg}, state=%State{socket: socket}) do

    with {:ok, payload} <- Poison.decode(msg) do
      if Renderer.active? do
        Renderer.input(payload)
      else
        Calibration.calibrate(payload)
      end
    end
    :inet.setopts(socket, [{:active, :once}])
    {:noreply, state}
  end
end
