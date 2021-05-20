defmodule DslDashboard.ExampleWatcher.Utils do
  require Logger
  alias DslDashboard.ExampleWatcher.Project
  
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

end
