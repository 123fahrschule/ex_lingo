defmodule ExLingo.Migrations.Postgresql.V03Test do
  use ExLingo.Test.DataCase, async: false

  alias ExLingo.Test.Repo

  @prefix "ex_lingo_v03_down_test"

  defmodule DownMigration do
    use Ecto.Migration

    def down do
      ExLingo.Migrations.Postgresql.V03.down(%{prefix: "ex_lingo_v03_down_test"})
    end
  end

  setup do
    Repo.query!("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
    Repo.query!("CREATE SCHEMA #{@prefix}")

    Repo.query!("""
    CREATE TABLE #{@prefix}.ex_lingo_messages (
      id bigserial PRIMARY KEY,
      domain_id bigint,
      context text,
      msgid text
    )
    """)

    Repo.query!("""
    CREATE UNIQUE INDEX ex_lingo_messages_domain_id_context_msgid_index
    ON #{@prefix}.ex_lingo_messages (domain_id, context, msgid) NULLS NOT DISTINCT
    """)

    on_exit(fn -> Repo.query!("DROP SCHEMA IF EXISTS #{@prefix} CASCADE") end)

    :ok
  end

  test "down tolerates application-source objects already removed by later migrations" do
    assert :ok =
             Ecto.Migration.Runner.run(
               Repo,
               Repo.config(),
               3,
               DownMigration,
               :forward,
               :down,
               :down,
               log: false
             )

    assert {:ok, %{rows: [[nil]]}} =
             Repo.query("SELECT to_regclass('#{@prefix}.ex_lingo_application_sources')")

    assert {:ok, %{rows: [[nil]]}} =
             Repo.query(
               "SELECT to_regclass('#{@prefix}.ex_lingo_messages_application_source_id_domain_id_context_msgid_index')"
             )
  end
end
