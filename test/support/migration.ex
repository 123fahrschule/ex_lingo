defmodule ExLingo.Test.Migration do
  @moduledoc false

  use Ecto.Migration

  @current_version ExLingo.Migrations.Postgresql.current_version()

  def up do
    ExLingo.Migration.up(version: @current_version)
  end

  def down do
    ExLingo.Migration.down(version: @current_version)
  end
end
