defmodule DslDashboard.ExampleWatcher.SrcMonitor do
  use GenServer
  require Logger
  alias DslDashboard.ExampleWatcher.{Utils,Project}
  use Pile

  @throttle_timeout_ms 100

  defmodule State do
    defstruct [:throttle_timer, :file_events, :watcher_pid, :project]
  end

  @impl GenServer
  def init(project) do
    dirs = Project.beam_dirs(project)
    {:ok, watcher_pid} =
      FileSystem.start_link(
        dirs: dirs,
        backend: Application.get_env(:file_system, :backend)
      )

    FileSystem.subscribe(watcher_pid)
    Logger.debug("ExSync source monitor started: #{inspect dirs}.")
    {:ok, %State{watcher_pid: watcher_pid, project: project}}
  end

  @impl GenServer
  def handle_info({:file_event, watcher_pid, {path, events}},
    %{watcher_pid: watcher_pid, project: project} = state) do
    
    matching_extension? = Path.extname(path) in Project.src_extensions(project)

    # This varies based on editor and OS - when saving a file in neovim on linux,
    # events received are:
    #   :modified
    #   :modified, :closed
    #   :attribute
    # Rather than coding specific behaviors for each OS, look for the modified event in
    # isolation to trigger things.
    matching_event? = :modified in events

    Logger.debug("ExSync source change: #{inspect path}")

    state =
      if matching_extension? && matching_event? do
        maybe_recompile(state)
      else
        state
      end

    {:noreply, state}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid} = state) do
    Logger.debug("ExSync src monitor stopped.")
    {:noreply, state}
  end

  def handle_info(:throttle_timer_complete, state) do
    Project.recompile(state.project)
    state = %State{state | throttle_timer: nil}
    {:noreply, state}
  end

  defp maybe_recompile(%State{throttle_timer: nil} = state) do
    throttle_timer = Process.send_after(self(), :throttle_timer_complete, @throttle_timeout_ms)
    %State{state | throttle_timer: throttle_timer}
  end

  defp maybe_recompile(%State{} = state), do: state
end
