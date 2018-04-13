defmodule IfThen.Calibration do
  use GenServer

  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def calibrate(values) do
    GenServer.call(__MODULE__, {:calibrate, values})
  end

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  def handle_call({:calibrate, values}, _from, state) do
#    IO.inspect values, label: "calibrate"
    {:reply, :ok, values}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
