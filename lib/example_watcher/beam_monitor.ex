defmodule DslDashboard.ExampleWatcher.BeamMonitor do
  use GenServer
  use Pile
  require Logger
  alias DslDashboard.ExampleWatcher.{LowLevel,Project}

  @throttle_timeout_ms 100

  defmodule State do
    @enforce_keys [
      :throttle_timer,
      :watcher_pid,
      :unload_set,
      :reload_set,
      :project
    ]
    defstruct [:throttle_timer, :watcher_pid, :unload_set, :reload_set, :project]
  end

  @impl GenServer
  def init(project) do
    dirs = Project.beam_dirs(project)
    {:ok, watcher_pid} = FileSystem.start_link(dirs: dirs)

    if Project.load_first(project), do: load_all_beam_files(dirs, project)
    
    FileSystem.subscribe(watcher_pid)
    Logger.debug("ExSync beam monitor started: #{inspect dirs}")

    state = %State{
      throttle_timer: nil,
      watcher_pid: watcher_pid,
      unload_set: MapSet.new(),
      reload_set: MapSet.new(),
      project: project
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:file_event, _watcher_pid, {path, events}}, state) do
    action = action(Path.extname(path), path, events)

    state =
      track_module_change(action, path, state)
      # TODO: Is this correct?
      |> maybe_update_throttle_timer()

    {:noreply, state}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid} = state) do
    Logger.debug("beam monitor stopped")
    {:noreply, state}
  end

  def handle_info(:throttle_timer_complete, state) do
    state = reload_and_unload_modules(state)
    state = %State{state | throttle_timer: nil}

    {:noreply, state}
  end

  defp action(".beam", path, events) do
    case {:created in events, :removed in events, :modified in events, File.exists?(path)} do
      # update
      {_, _, true, true} -> :reload_module
      # temp file
      {true, true, _, false} -> :nothing
      # remove
      {_, true, _, false} -> :unload_module
      # create and other
      _ -> :nothing
    end
  end

  defp action(_extname, _path, _events), do: :nothing

  defp track_module_change(:nothing, _module, state), do: state

  defp track_module_change(:reload_module, module, state) do
    %State{reload_set: reload_set, unload_set: unload_set} = state

    %State{
      state
      | reload_set: MapSet.put(reload_set, module),
        unload_set: MapSet.delete(unload_set, module)
    }
  end

  defp track_module_change(:unload_module, module, state) do
    %State{reload_set: reload_set, unload_set: unload_set} = state

    %State{
      state
      | reload_set: MapSet.delete(reload_set, module),
        unload_set: MapSet.put(unload_set, module)
    }
  end

  defp maybe_update_throttle_timer(%State{throttle_timer: nil} = state) do
    %State{reload_set: reload_set, unload_set: unload_set} = state

    if Enum.empty?(reload_set) && Enum.empty?(unload_set) do
      state
    else
      # Logger.debug("BeamMonitor Start throttle timer")
      throttle_timer = Process.send_after(self(), :throttle_timer_complete, @throttle_timeout_ms)
      %State{state | throttle_timer: throttle_timer}
    end
  end

  defp maybe_update_throttle_timer(state), do: state

  defp reload_and_unload_modules(%State{} = state) do
    %State{reload_set: reload_set, unload_set: unload_set} = state

    load_modules(reload_set, state.project)
    unload_modules(unload_set)

    %State{state | reload_set: MapSet.new(), unload_set: MapSet.new()}
  end

  defp load_all_beam_files(dirs, project) do
    Logger.debug("Initial load of all beam files.")
    paths = LowLevel.all_beam_paths(dirs)
    load_modules(paths, project)
  end  

  defp load_modules(reload_set, project) do 
    Enum.each(reload_set, fn module_path ->
      {:module, module} = LowLevel.reload(module_path)
      Project.reload_callback(project).(module)
    end)
  end

  defp unload_modules(unload_set) do 
    Enum.each(unload_set, fn module_path ->
      LowLevel.unload(module_path)
    end)
  end
end
