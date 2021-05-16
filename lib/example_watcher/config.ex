require Logger

defmodule DslDashboard.ExampleWatcher.Config do
  def reload_timeout do
    Application.get_env(application(), :reload_timeout, 150)
  end

  def logging_enabled do
    Application.get_env(application(), :logging_enabled, true)
  end

  def reload_callback do
    Application.get_env(application(), :reload_callback)
  end

  def load_first do
    Application.get_env(application(), :load_first, false)
  end

  def beam_dirs do
    Application.get_env(application(), :beam_dirs, :not_found)
  end

  def src_monitor_enabled do
    case Application.fetch_env(application(), :src_monitor) do
      :error ->
        Logger.debug([
          "Defaulting to enable source monitor, set config :exsync, src_monitor: false",
          " to disable\n"
        ])

        true

      {:ok, value} when value in [true, false] ->
        value

      {:ok, invalid} ->
        Logger.error([
          "Value #{inspect(invalid)} not valid for setting :src_monitor, expected",
          " true or false.  Enabling source monitor."
        ])

        true
    end
  end

  def src_dirs do
    Application.get_env(application(), :src_dirs, :not_found)
  end

  def application do
    :dsl_dashboard
  end

  def src_extensions, do: [".ex"]

  def compile_here do
    Application.get_env(application(), :compile_here, :not_found)
  end
end
