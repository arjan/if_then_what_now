defmodule IfThen.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      worker(IfThen.MessageReceiver, []),
      worker(IfThen.Calibration, [:GSR1, {100, 450}], id: :GSR1),
      worker(IfThen.Calibration, [:GSR2, {100, 450}], id: GSR2),
      worker(IfThen.Calibration, [:HeartBPM, {20, 280}], id: :HeartBPM),
      supervisor(IfThenWeb.Endpoint, []),
      # Start your own worker by calling: IfThen.Worker.start_link(arg1, arg2, arg3)
      # worker(IfThen.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IfThen.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    IfThenWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
