defmodule ExLingo.Test.Repo.Migrations.UpdateExLingoToV10 do
  use Ecto.Migration

  def up, do: ExLingo.Migration.up(version: 10)

  def down, do: ExLingo.Migration.down(version: 10)
end
