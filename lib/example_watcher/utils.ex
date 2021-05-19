defmodule DslDashboard.ExampleWatcher.Utils do
  require Logger
  alias DslDashboard.ExampleWatcher.Config
  
  def recomplete do
    Logger.debug("running mix compile")

    System.cmd("mix", ["compile"], cd: Config.compile_here(),
      stderr_to_stdout: true,
      env: [{"MIX_ENV", "test"}]
    )
    |> log_compile_cmd()
  end

  def unload(module) when is_atom(module) do
    Logger.debug("unload module #{inspect module}")
    module |> :code.purge()
    module |> :code.delete()
  end

  def unload(beam_path) do
    beam_path |> Path.basename(".beam") |> String.to_atom() |> unload
  end

  def reload(beam_path) do
    file = beam_path |> to_charlist
    {:ok, binary, _} = :erl_prim_loader.get_file(file)
    module = beam_path |> Path.basename(".beam") |> String.to_atom()
    Logger.debug("load module #{inspect module}")
    :code.load_binary(module, file, binary)
  end

  def all_beam_paths(dirs) do
    from_one_dir = fn dir ->
      {:ok, paths} = File.ls(dir)
      paths
      |> Enum.filter(&(Path.extname(&1) == ".beam"))
      |> Enum.map(&(Path.join(dir, &1)))
    end
      
    Enum.flat_map(dirs, from_one_dir)
  end

  defp log_compile_cmd({output, status} = result) when is_binary(output) and status > 0 do
    Logger.error(["error while compiling\n", output])
    result
  end

  defp log_compile_cmd({"", _status} = result), do: result

  defp log_compile_cmd({output, _status} = result) when is_binary(output) do
    message = ["compiling\n", output]

    if String.contains?(output, "warning:") do
      Logger.warn(message)
    else
      Logger.debug(message)
    end

    result
  end
end
