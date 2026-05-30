defmodule ExLingo.Test.Repo.Migrations.UpdateExLingoToV8 do
  use Ecto.Migration

  def up, do: ExLingo.Migration.up(version: 8)

  def down, do: ExLingo.Migration.down(version: 8)
end
