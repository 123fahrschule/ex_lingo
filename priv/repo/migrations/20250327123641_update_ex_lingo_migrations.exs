defmodule ExLingo.Test.Repo.Migrations.UpdateExLingoMigrations do
  use Ecto.Migration

  def up do
    ExLingo.Migration.up(version: 5)
  end

  def down do
    ExLingo.Migration.down(version: 5)
  end
end
