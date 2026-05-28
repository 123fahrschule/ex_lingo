defmodule ExLingo.Test.Repo.Migrations.UpdateExLingoToV7 do
  use Ecto.Migration

  def up, do: ExLingo.Migration.up(version: 7)

  def down, do: ExLingo.Migration.down(version: 7)
end
