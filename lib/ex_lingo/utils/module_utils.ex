defmodule ExLingo.Utils.ModuleUtils do
  @moduledoc false

  @doc """
  Checks if a module exists in the current application.
  """
  @spec module_exists?(atom()) :: boolean()
  def module_exists?(module_name) do
    case Code.ensure_compiled(module_name) do
      {:module, _module} -> true
      _other -> false
    end
  end
end
