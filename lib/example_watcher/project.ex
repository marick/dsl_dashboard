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
  use Pile

  def constantly(value) do
    fn _ -> value end
  end

  defaults_may_be_overridden(
    reload_timeout: 150,
    logging_enabled: true,
    reload_callback: constantly(:irrelevant_return_value),
    load_first: false,
    src_dirs: []
  )

  values_must_be_provided [
    :beam_dirs, :compile_here
  ]
end
