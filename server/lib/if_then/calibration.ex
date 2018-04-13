defmodule IfThen.Calibration do
  use GenServer

  require Logger

  def start_link(name, sensor_range) do
    GenServer.start_link(__MODULE__, [name, sensor_range], name: name)
  end

  def calibrate(pid, value) do
    GenServer.call(pid, {:calibrate, value})
  end

  def average(pid) do
    GenServer.call(pid, :average)
  end


  ##

  @window 10

  defmodule State do
    defstruct [
      name: nil,
      samples: [],
      average: 0,
      sensor_range: {0, 100},
      calibrate_range: {0, 100}
    ]
  end

  def init([name, sensor_range]) do
    {:ok, %State{name: name, samples: [], sensor_range: sensor_range}}
  end

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  def handle_call({:calibrate, value}, _from, %{sensor_range: {min, max}} = state) when value >= min and value <= max do
    IO.inspect value, label: state.name
    samples = [value | state.samples] |> Enum.take(@window)
    average = Enum.sum(samples) / @window
    Logger.debug "#{state.name} - #{average}"
    {:reply, :ok, %State{state | samples: samples, average: average}}
  end
  def handle_call({:calibrate, value}, _from, state) do
    Logger.warn "#{state.name} - sensor outside range (#{value})"
    {:reply, :ok, state}
  end
  def handle_call(:average, _from, state) do
    {:reply, state.average, state}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
