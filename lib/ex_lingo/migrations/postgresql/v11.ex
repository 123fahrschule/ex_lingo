defmodule ExLingo.Migrations.Postgresql.V11 do
  @moduledoc """
  ExLingo PostgreSQL V11 Migrations

  Removes the application-source concept: drops `ex_lingo_application_sources`
  and the `application_source_id` columns on messages and glossary entries, and
  narrows the message uniqueness key to `(domain_id, context, msgid)`.
  """

  use Ecto.Migration

  @default_prefix "public"
  @ex_lingo_messages "ex_lingo_messages"
  @ex_lingo_glossary_entries "ex_lingo_glossary_entries"
  @ex_lingo_application_sources "ex_lingo_application_sources"

  def up(opts) do
    prefix = prefix(opts)
    quoted_prefix = quoted_prefix(opts)

    drop_if_exists unique_index(
                     @ex_lingo_messages,
                     [:application_source_id, :domain_id, :context, :msgid],
                     prefix: prefix
                   )

    execute """
      ALTER TABLE #{quoted_prefix}.#{@ex_lingo_messages}
        DROP COLUMN IF EXISTS application_source_id;
    """

    execute """
      ALTER TABLE IF EXISTS #{quoted_prefix}.#{@ex_lingo_glossary_entries}
        DROP COLUMN IF EXISTS application_source_id;
    """

    execute "DROP TABLE IF EXISTS #{quoted_prefix}.#{@ex_lingo_application_sources};"

    create_if_not_exists unique_index(@ex_lingo_messages, [:domain_id, :context, :msgid],
                           prefix: prefix,
                           nulls_distinct: false
                         )
  end

  # Removing the application-source tables/columns is destructive; restoring it
  # would require recreating the table and its data from a backup.
  def down(_opts), do: :ok

  defp prefix(opts), do: Map.get(opts, :prefix, @default_prefix)

  defp quoted_prefix(opts) do
    Map.get(opts, :quoted_prefix, ~s("#{String.replace(prefix(opts), ~s("), ~s(""))}"))
  end
end
