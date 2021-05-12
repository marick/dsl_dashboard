defmodule DslDashboard.Application do
  use Pile
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      DslDashboardWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: DslDashboard.PubSub},
      # Start the Endpoint (http/https)
      DslDashboardWeb.Endpoint,
      # Start a worker by calling: DslDashboard.Worker.start_link(arg)
      # {DslDashboard.Worker, arg}
      EctoTestDSL.TestDataServer,
      ExSync.Logger.Server,
      ExSync.SrcMonitor,
      ExSync.BeamMonitor,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DslDashboard.Supervisor]
    Supervisor.start_link(children, opts) |> ppp
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DslDashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
