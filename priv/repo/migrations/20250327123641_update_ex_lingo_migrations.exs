defmodule ExLingo.Test.Repo.Migrations.UpdateExLingoMigrations do
  use Ecto.Migration

  def up do
     ExLingo.Migration.up(version: 4)
   end

   def down do
     ExLingo.Migration.down(version: 4)
   end
end
