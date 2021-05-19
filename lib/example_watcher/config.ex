require Logger

defmodule DslDashboard.ExampleWatcher.Config.Macro do
  alias __MODULE__, as: Here
  
  defp application, do: :dsl_dashboard

  def get_env(name, default), do: Application.get_env(application(), name, default)

  def def_required(name_atom) do
    guid = "c792b687-fe77-446f-abbc-ae912b02a3d8"
    function_name = {name_atom, [], nil}
    quote do
      def unquote(function_name) do
        case get_env(unquote(name_atom), unquote(guid)) do
          unquote(guid) ->
            raise "Missing example watcher config: #{inspect unquote(name_atom)}`"
          result ->
            result
        end
      end
    end
  end

  def def_optional({name_atom, default}) do
    function_name = {name_atom, [], nil}
    quote do
      def unquote(function_name),
        do: get_env(unquote(name_atom), unquote(default))
    end
  end
  
  defmacro values_must_be_provided(names) when is_list(names) do
    for name <- names, do: Here.def_required(name)
  end

  defmacro defaults_may_be_overridden(pairs) when is_list(pairs) do
    for pair <- pairs, do: Here.def_optional(pair)
  end
end

defmodule DslDashboard.ExampleWatcher.Config do
  import DslDashboard.ExampleWatcher.Config.Macro

  defaults_may_be_overridden [
    reload_timeout: 150,
    logging_enabled: true,
    reload_callback: fn _module -> :irrelevant_return_value end ,
    load_first: false,
    src_dirs: []
  ]

  values_must_be_provided [
    :beam_dirs, :compile_here
  ]
  

  def application do
    :dsl_dashboard
  end

  def src_extensions, do: [".ex"]
end
