defmodule DslDashboard.ExampleWatcher do
  use GenServer
  use Pile
  alias DslDashboard.ExampleWatcher.{SrcMonitor, BeamMonitor, Project}

  def watch_project(project_name) do
    project_pairs()
    |> Map.new
    |> Map.fetch!(project_name)
  end


  def start_link([]) do
    GenServer.start_link(__MODULE__, first_project())
  end


  @impl GenServer
  def init(start_with) do
    GenServer.start_link(SrcMonitor, start_with)
    GenServer.start_link(BeamMonitor, start_with)

    {:ok, :no_state}
  end

  defp project_pairs do 
    Mix.Project.config[:app]
    |> Application.get_env(:example_watchers)
    |> Keyword.get(:projects)
  end

  defp first_project do
    [{_name, data} | _] = project_pairs()
    data
  end
end
