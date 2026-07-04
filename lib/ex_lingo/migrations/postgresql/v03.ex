defmodule ExLingo.Migrations.Postgresql.V03 do
  @moduledoc """
  ExLingo PostgreSQL V3 Migrations
  """

  use Ecto.Migration
  alias ExLingo.Utils.Colors

  @default_prefix "public"
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
    prefix = prefix(opts)

    create_if_not_exists table(@ex_lingo_application_sources,
                           prefix: prefix,
                           primary_key: false
                         ) do
      add(:id, :bigserial, primary_key: true)
      add(:name, :string)
      add(:description, :text)
      add(:color, :string, null: false, default: Colors.default_color())
      timestamps()
    end

    create_if_not_exists unique_index(@ex_lingo_application_sources, [:name], prefix: prefix)
  end

  def up_ex_lingo_messages(opts) do
    prefix = prefix(opts)

    alter table(@ex_lingo_messages, prefix: prefix) do
      add(
        :application_source_id,
        references(@ex_lingo_application_sources, prefix: prefix, type: :bigint),
        null: true
      )
    end

    drop unique_index(@ex_lingo_messages, [:domain_id, :context, :msgid], prefix: prefix)

    create_if_not_exists unique_index(
                           @ex_lingo_messages,
                           [
                             :application_source_id,
                             :domain_id,
                             :context,
                             :msgid
                           ],
                           prefix: prefix,
                           nulls_distinct: false
                         )
  end

  def down_application_sources(opts) do
    drop_if_exists table(@ex_lingo_application_sources, prefix: prefix(opts))
  end

  def down_ex_lingo_messages(opts) do
    prefix = prefix(opts)

    drop_if_exists unique_index(
                     @ex_lingo_messages,
                     [
                       :application_source_id,
                       :domain_id,
                       :context,
                       :msgid
                     ],
                     prefix: prefix
                   )

    create_if_not_exists unique_index(@ex_lingo_messages, [:domain_id, :context, :msgid],
                           prefix: prefix,
                           nulls_distinct: false
                         )

    alter table(@ex_lingo_messages, prefix: prefix) do
      remove_if_exists(:application_source_id)
    end
  end

  defp prefix(opts), do: Map.get(opts, :prefix, @default_prefix)
end
