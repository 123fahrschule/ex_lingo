defmodule ExLingo.Test.Repo.Migrations.UpdateExLingoToV9 do
  use Ecto.Migration

  def up, do: ExLingo.Migration.up(version: 9)

  def down, do: ExLingo.Migration.down(version: 9)
end
