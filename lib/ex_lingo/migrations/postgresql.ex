defmodule ExLingo.Migrations.Postgresql do
  @moduledoc false

  @behaviour ExLingo.Migration

  use Ecto.Migration

  @initial_version 1
  @current_version 7
  @default_prefix "public"

  @doc false
  def initial_version, do: @initial_version

  @doc false
  def current_version, do: @current_version

  @impl ExLingo.Migration
  def up(opts) do
    opts = with_defaults(opts, @current_version)
    initial = migrated_version(opts)

    cond do
      initial == 0 ->
        create_schema(opts)
        change(@initial_version..opts.version, :up, opts)

      initial < opts.version ->
        create_schema(opts)
        change((initial + 1)..opts.version, :up, opts)

      true ->
        :ok
    end
  end

  @impl ExLingo.Migration
  def down(opts) do
    opts = with_defaults(opts, @initial_version)
    initial = max(migrated_version(opts), @initial_version)

    if initial >= opts.version do
      change(initial..opts.version, :down, opts)
    end
  end

  @impl ExLingo.Migration
  def migrated_version(opts) do
    opts = with_defaults(opts, @initial_version)

    repo = Map.get_lazy(opts, :repo, fn -> repo() end)
    prefix = Map.fetch!(opts, :prefix)

    query = """
    SELECT description
    FROM pg_class
    LEFT JOIN pg_description ON pg_description.objoid = pg_class.oid
    LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE pg_class.relname = 'ex_lingo_messages'
    AND pg_namespace.nspname = $1
    """

    case repo.query(query, [prefix], log: false) do
      {:ok, %{rows: [[version]]}} when is_binary(version) -> parse_version(version)
      _ -> 0
    end
  end

  defp change(range, direction, opts) do
    for index <- range do
      pad_idx = String.pad_leading(to_string(index), 2, "0")

      [__MODULE__, "V#{pad_idx}"]
      |> Module.concat()
      |> apply(direction, [opts])
    end

    case direction do
      :up -> record_version(opts, Enum.max(range))
      :down -> record_version(opts, Enum.min(range) - 1)
    end
  end

  defp record_version(_opts, 0), do: :ok

  defp record_version(%{quoted_prefix: quoted_prefix}, version) do
    execute "COMMENT ON TABLE #{quoted_prefix}.#{quote_identifier("ex_lingo_messages")} IS '#{version}'"
  end

  defp create_schema(%{create_schema: true, quoted_prefix: quoted_prefix}) do
    execute "CREATE SCHEMA IF NOT EXISTS #{quoted_prefix}"
  end

  defp create_schema(_opts), do: :ok

  defp with_defaults(opts, version) do
    opts = Enum.into(opts, %{})
    repo = Map.get(opts, :repo) || repo()
    repo_prefix = repo_default_prefix(repo)
    opts = Map.merge(%{prefix: repo_prefix || @default_prefix, version: version}, opts)
    prefix = Map.fetch!(opts, :prefix)

    opts
    |> Map.put_new(:create_schema, prefix != @default_prefix)
    |> Map.put_new(:quoted_prefix, quote_identifier(prefix))
  end

  defp repo_default_prefix(repo) do
    if function_exported?(repo, :default_options, 1) do
      repo.default_options(:all) |> Keyword.get(:prefix)
    end
  rescue
    UndefinedFunctionError -> nil
  end

  defp quote_identifier(identifier) do
    identifier
    |> to_string()
    |> String.replace(~s("), ~s(""))
    |> then(&~s("#{&1}"))
  end

  defp parse_version(version) do
    case Integer.parse(version) do
      {version, ""} -> version
      _invalid -> 0
    end
  end
end
