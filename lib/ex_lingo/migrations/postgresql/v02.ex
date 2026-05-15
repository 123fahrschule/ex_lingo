defmodule ExLingo.Migrations.Postgresql.V02 do
  @moduledoc """
  ExLingo PostgreSQL V2 Migrations
  """

  use Ecto.Migration

  @default_prefix "public"
  @ex_lingo_singular_translations "ex_lingo_singular_translations"
  @ex_lingo_plural_translations "ex_lingo_plural_translations"

  def up(opts) do
    up_fuzzy_search(opts)
  end

  def down(opts) do
    down_fuzzy_search(opts)
  end

  def up_fuzzy_search(opts) do
    quoted_prefix = quoted_prefix(opts)

    [@ex_lingo_plural_translations, @ex_lingo_singular_translations]
    |> Enum.each(fn table_name ->
      execute """
        ALTER TABLE #{quoted_prefix}.#{table_name}
          ADD COLUMN IF NOT EXISTS searchable tsvector
          GENERATED ALWAYS AS (
            setweight(to_tsvector('simple', coalesce(translated_text, '')), 'A')
          ) STORED;
      """

      execute """
        CREATE INDEX IF NOT EXISTS #{table_name}_searchable_idx ON #{quoted_prefix}.#{table_name} USING gin(searchable);
      """
    end)

    execute("CREATE EXTENSION IF NOT EXISTS unaccent;")
  end

  def down_fuzzy_search(opts) do
    quoted_prefix = quoted_prefix(opts)

    [@ex_lingo_plural_translations, @ex_lingo_singular_translations]
    |> Enum.each(fn table_name ->
      execute "DROP INDEX IF EXISTS #{quoted_prefix}.#{table_name}_searchable_idx;"

      execute """
        ALTER TABLE #{quoted_prefix}.#{table_name}
          DROP COLUMN IF EXISTS searchable;
      """
    end)

    execute("DROP EXTENSION IF EXISTS unaccent;")
  end

  defp quoted_prefix(opts) do
    prefix = Map.get(opts, :prefix, @default_prefix)
    Map.get(opts, :quoted_prefix, ~s("#{String.replace(prefix, ~s("), ~s(""))}"))
  end
end
