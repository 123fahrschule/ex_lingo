defmodule ExLingo.Repo do
  def get_repo do
    ExLingo.config().repo
  end

  def opts(opts \\ []) do
    case configured_prefix() do
      nil -> opts
      prefix -> Keyword.put_new(opts, :prefix, prefix)
    end
  end

  def configured_prefix do
    ExLingo.config().prefix || repo_default_prefix()
  rescue
    RuntimeError -> nil
  end

  def get_adapter_name do
    case get_repo().__adapter__() do
      Ecto.Adapters.Postgres ->
        :postgres

      adapter ->
        raise ArgumentError, "ExLingo supports PostgreSQL repos only, got: #{inspect(adapter)}"
    end
  end

  defp repo_default_prefix do
    get_repo()
    |> apply(:default_options, [:all])
    |> Keyword.get(:prefix)
  end
end
