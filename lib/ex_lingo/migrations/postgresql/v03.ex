defmodule ExLingo.Migrations.Postgresql.V03 do
  @moduledoc """
  ExLingo PostgreSQL V3 Migrations
  """

  use Ecto.Migration
  alias ExLingo.Utils.Colors

  @ex_lingo_application_sources "ex_lingo_application_sources"
  @ex_lingo_messages "ex_lingo_messages"

  def up(opts) do
    [
      &up_application_sources/1,
      &up_ex_lingo_messages/1
    ]
    |> Enum.each(&apply(&1, [opts]))
  end

  def down(opts) do
    [
      &down_ex_lingo_messages/1,
      &down_application_sources/1
    ]
    |> Enum.each(&apply(&1, [opts]))
  end

  def up_application_sources(opts) do
    prefix = opts.prefix

    create_if_not_exists table(@ex_lingo_application_sources, prefix: prefix) do
      add(:name, :string)
      add(:description, :text)
      add(:color, :string, null: false, default: Colors.default_color())
      timestamps()
    end

    create_if_not_exists unique_index(@ex_lingo_application_sources, [:name], prefix: prefix)
  end

  def up_ex_lingo_messages(opts) do
    prefix = opts.prefix

    alter table(@ex_lingo_messages, prefix: prefix) do
      add(:application_source_id, references(@ex_lingo_application_sources, prefix: prefix),
        null: true
      )
    end

    drop unique_index(@ex_lingo_messages, [:context_id, :domain_id, :msgid], prefix: prefix)

    create_if_not_exists unique_index(
                           @ex_lingo_messages,
                           [
                             :application_source_id,
                             :context_id,
                             :domain_id,
                             :msgid
                           ],
                           prefix: prefix,
                           nulls_distinct: false
                         )
  end

  def down_application_sources(opts) do
    drop table(@ex_lingo_application_sources, prefix: opts.prefix)
  end

  def down_ex_lingo_messages(opts) do
    prefix = opts.prefix

    drop unique_index(
           @ex_lingo_messages,
           [
             :application_source_id,
             :context_id,
             :domain_id,
             :msgid
           ], prefix: prefix)

    create_if_not_exists unique_index(@ex_lingo_messages, [:context_id, :domain_id, :msgid],
                           prefix: prefix
                         )

    alter table(@ex_lingo_messages, prefix: prefix) do
      remove(:application_source_id)
    end
  end
end
