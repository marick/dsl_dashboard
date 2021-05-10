defmodule DslDashboard.ExampleWatcher.Supervisor do
  use Supervisor
  alias DslDashboard.ExampleWatcher

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [DslDashboard.ExampleWatcher]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end
