defmodule ExLingo.Migrations.Postgresql.V04 do
  @moduledoc """
  ExLingo PostgreSQL V4 Migrations
  """

  use Ecto.Migration

  @doc """
  Ensure that the `default` context exists.
  """
  def up(opts) do
    prefix = opts.quoted_prefix

    # Insert the 'default' context if it doesn't exist
    execute("""
    INSERT INTO #{prefix}.ex_lingo_contexts (name, inserted_at, updated_at)
    VALUES ('default', NOW(), NOW())
    ON CONFLICT (name) DO NOTHING;
    """)

    flush()

    # Update messages with null context_id to use the 'default' context's ID
    execute("""
    UPDATE #{prefix}.ex_lingo_messages
    SET context_id = (SELECT id FROM #{prefix}.ex_lingo_contexts WHERE name = 'default')
    WHERE context_id IS NULL;
    """)
  end

  # This is an intentionally one-way data migration. Reverting would require
  # restoring the previous null context assignments from a backup.
  def down(_opts), do: nil
end
