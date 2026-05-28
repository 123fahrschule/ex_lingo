defmodule ExLingo.Migrations.Postgresql.V04 do
  @moduledoc """
  ExLingo PostgreSQL V4 Migrations
  """

  use Ecto.Migration

  @doc """
  Obsolete after contexts became message text metadata instead of a managed table.
  """
  def up(_opts), do: nil

  # This is an intentionally one-way data migration. Reverting would require
  # restoring the previous null context assignments from a backup.
  def down(_opts), do: nil
end
