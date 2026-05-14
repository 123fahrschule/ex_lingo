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
    prefix = Map.get(opts, :prefix, @default_prefix)

    [@ex_lingo_plural_translations, @ex_lingo_singular_translations]
    |> Enum.each(fn table_name ->
      execute """
        ALTER TABLE #{prefix}.#{table_name}
          ADD COLUMN IF NOT EXISTS searchable tsvector
          GENERATED ALWAYS AS (
            setweight(to_tsvector('simple', coalesce(translated_text, '')), 'A')
          ) STORED;
      """

      execute """
        CREATE INDEX IF NOT EXISTS #{table_name}_searchable_idx ON #{prefix}.#{table_name} USING gin(searchable);
      """
    end)

    execute("CREATE EXTENSION IF NOT EXISTS unaccent;")
  end

  def down_fuzzy_search(_opts) do
    execute("DROP EXTENSION IF EXISTS unaccent;")
  end
end
