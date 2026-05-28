defmodule ExLingo.Migrations.Postgresql.V07 do
  @moduledoc """
  ExLingo PostgreSQL V7 Migrations
  """

  use Ecto.Migration

  @default_prefix "public"
  @ex_lingo_messages "ex_lingo_messages"
  @ex_lingo_contexts "ex_lingo_contexts"
  @ex_lingo_glossary_entries "ex_lingo_glossary_entries"

  def up(opts) do
    prefix = prefix(opts)
    quoted_prefix = quoted_prefix(opts)

    execute """
      ALTER TABLE #{quoted_prefix}.#{@ex_lingo_messages}
        ADD COLUMN IF NOT EXISTS context text,
        ADD COLUMN IF NOT EXISTS context_review_requested_at timestamp(0),
        ADD COLUMN IF NOT EXISTS context_review_context text;
    """

    execute """
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1
          FROM information_schema.tables
          WHERE table_schema = #{quote_literal(prefix)}
          AND table_name = '#{@ex_lingo_contexts}'
        ) THEN
          EXECUTE format(
            'UPDATE %I.%I messages
             SET context = contexts.name
             FROM %I.%I contexts
             WHERE messages.context_id = contexts.id
             AND messages.context IS NULL',
            #{quote_literal(prefix)},
            '#{@ex_lingo_messages}',
            #{quote_literal(prefix)},
            '#{@ex_lingo_contexts}'
          );
        END IF;
      END $$;
    """

    execute """
      UPDATE #{quoted_prefix}.#{@ex_lingo_messages}
      SET context = 'default'
      WHERE context IS NULL;
    """

    drop_if_exists unique_index(@ex_lingo_messages, [:context_id, :domain_id, :msgid],
                     prefix: prefix
                   )

    drop_if_exists unique_index(
                     @ex_lingo_messages,
                     [:application_source_id, :context_id, :domain_id, :msgid],
                     prefix: prefix
                   )

    drop_if_exists unique_index(
                     @ex_lingo_messages,
                     [:application_source_id, :domain_id, :context, :msgid],
                     prefix: prefix
                   )

    execute """
      ALTER TABLE #{quoted_prefix}.#{@ex_lingo_messages}
        DROP COLUMN IF EXISTS searchable,
        DROP COLUMN IF EXISTS context_id;
    """

    execute """
      ALTER TABLE #{quoted_prefix}.#{@ex_lingo_messages}
        ADD COLUMN searchable tsvector
        GENERATED ALWAYS AS (
          setweight(to_tsvector('english', coalesce(msgid, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(context, '')), 'B')
        ) STORED;
    """

    execute """
      CREATE INDEX IF NOT EXISTS #{@ex_lingo_messages}_searchable_idx
      ON #{quoted_prefix}.#{@ex_lingo_messages}
      USING gin(searchable);
    """

    create_if_not_exists unique_index(
                           @ex_lingo_messages,
                           [:application_source_id, :domain_id, :context, :msgid],
                           prefix: prefix,
                           nulls_distinct: false
                         )

    execute """
      ALTER TABLE IF EXISTS #{quoted_prefix}.#{@ex_lingo_glossary_entries}
        DROP COLUMN IF EXISTS context_id;
    """

    execute "DROP TABLE IF EXISTS #{quoted_prefix}.#{@ex_lingo_contexts};"
  end

  # Context tables are intentionally removed. Rolling this migration back would
  # require restoring the old context rows and foreign keys from a backup.
  def down(_opts), do: nil

  defp prefix(opts), do: Map.get(opts, :prefix, @default_prefix)

  defp quoted_prefix(opts) do
    Map.get(opts, :quoted_prefix, ~s("#{String.replace(prefix(opts), ~s("), ~s(""))}"))
  end

  defp quote_literal(value) do
    "'#{String.replace(to_string(value), "'", "''")}'"
  end
end
