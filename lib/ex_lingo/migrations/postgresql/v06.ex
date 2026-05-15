defmodule ExLingo.Migrations.Postgresql.V06 do
  @moduledoc """
  ExLingo PostgreSQL V6 Migrations
  """

  use Ecto.Migration

  @ex_lingo_messages "ex_lingo_messages"

  def up(opts) do
    prefix = Map.get(opts, :prefix, "public")

    alter table(@ex_lingo_messages, prefix: prefix) do
      add(:source_references, {:array, :map}, null: false, default: [])
    end
  end

  def down(opts) do
    prefix = Map.get(opts, :prefix, "public")

    alter table(@ex_lingo_messages, prefix: prefix) do
      remove(:source_references)
    end
  end
end
