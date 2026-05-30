defmodule ExLingo.Migrations.Postgresql.V10 do
  @moduledoc """
  ExLingo PostgreSQL V10 Migrations

  Stores the source plural form (`msgid_plural`) on plural messages so it can be
  written back out when exporting to PO files. Populated on the next PO import.
  """

  use Ecto.Migration

  @default_prefix "public"
  @ex_lingo_messages "ex_lingo_messages"

  def up(opts) do
    execute("""
      ALTER TABLE #{quoted_prefix(opts)}.#{@ex_lingo_messages}
        ADD COLUMN IF NOT EXISTS msgid_plural text;
    """)
  end

  def down(opts) do
    execute("""
      ALTER TABLE #{quoted_prefix(opts)}.#{@ex_lingo_messages}
        DROP COLUMN IF EXISTS msgid_plural;
    """)
  end

  defp prefix(opts), do: Map.get(opts, :prefix, @default_prefix)

  defp quoted_prefix(opts) do
    Map.get(opts, :quoted_prefix, ~s("#{String.replace(prefix(opts), ~s("), ~s(""))}"))
  end
end
