defmodule ExLingo.Test.Repo.Migrations.UpdateExLingoToV11 do
  use Ecto.Migration

  def up, do: ExLingo.Migration.up(version: 11)

  def down, do: ExLingo.Migration.down(version: 11)
end
