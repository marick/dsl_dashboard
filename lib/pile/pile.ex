defmodule Pile do
  defmacro __using__(_) do
    quote do
      use Pile.MyPI
    end
  end
end  
