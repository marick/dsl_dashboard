defmodule DslDashboard.ExampleWatcher.Project.Macro do
  alias __MODULE__, as: Here
  require Logger
  use Pile
  
  def def_required(name_atom) do
    quote do
      def unquote(name_atom)(project_config),
        do: Map.fetch!(project_config, unquote(name_atom))
    end
  end

  def def_optional({name_atom, default}) do
    quote do
      def unquote(name_atom)(project_config),
        do: Map.get(project_config, unquote(name_atom), unquote(default))
    end
  end
  
  defmacro values_must_be_provided(names) when is_list(names) do
    for name <- names, do: Here.def_required(name)
  end

  defmacro defaults_may_be_overridden(pairs) when is_list(pairs) do
    for pair <- pairs, do: Here.def_optional(pair)
  end
end


defmodule DslDashboard.ExampleWatcher.Project do
  import DslDashboard.ExampleWatcher.Project.Macro
  require Logger
  use Pile

  defaults_may_be_overridden(
    reload_timeout: 150,
    logging_enabled: true,
    reload_callback: constantly(:irrelevant_return_value),
    load_first: false,
    src_dirs: [],
    src_extensions: [".ex"]
  )

  values_must_be_provided [
    :beam_dirs, :compile_here
  ]

  def recompile(project) do
    Logger.debug("running mix compile")

    System.cmd("mix", ["compile"], cd: Project.compile_here(project),
      stderr_to_stdout: true,
      env: [{"MIX_ENV", "test"}]
    )
    |> log_compile_cmd()
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

  defp constantly(value), do: fn _ -> value end
end
