defmodule DslDashboard.ExampleWatcher do
  use GenServer


  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, opts)

  # --------------------------------------------------------------------

  @dir "/Users/bem/src/examples_for_ecto_test_dsl/basics/_build/test/lib/app/ebin"

  def init(_) do
    IO.inspect "==================ExampleWatcher init"
    {:ok, watcher_pid} = FileSystem.start_link(dirs: [@dir])
    FileSystem.subscribe(watcher_pid) |> IO.inspect
    {:ok, %{}}
  end



  def handle_info(stuff, state) do
    IO.inspect stuff, label: "handle_info"
    {:noreply, state}
  end
    
    
    
  
end
