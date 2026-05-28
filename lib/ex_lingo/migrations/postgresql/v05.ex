defmodule ExLingo.Migrations.Postgresql.V05 do
  @moduledoc """
  ExLingo PostgreSQL V5 Migrations
  """

  use Ecto.Migration

  @ex_lingo_glossary_entries "ex_lingo_glossary_entries"
  @ex_lingo_domains "ex_lingo_domains"
  @ex_lingo_application_sources "ex_lingo_application_sources"

  def up(opts) do
    prefix = Map.get(opts, :prefix, "public")

    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"

    create_if_not_exists table(@ex_lingo_glossary_entries, prefix: prefix, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:source_locale, :string, null: false)
      add(:target_locale, :string, null: false)
      add(:source_term, :text, null: false)
      add(:target_term, :text, null: false)
      add(:usage_guidance, :text)
      add(:domain_id, references(@ex_lingo_domains, prefix: prefix, type: :bigint), null: true)

      add(
        :application_source_id,
        references(@ex_lingo_application_sources, prefix: prefix, type: :bigint),
        null: true
      )

      timestamps()
    end

    create_if_not_exists index(@ex_lingo_glossary_entries, [:source_locale, :target_locale],
                           prefix: prefix
                         )

    create_if_not_exists index(@ex_lingo_glossary_entries, [:domain_id], prefix: prefix)

    create_if_not_exists index(@ex_lingo_glossary_entries, [:application_source_id],
                           prefix: prefix
                         )

    create_if_not_exists index(
                           @ex_lingo_glossary_entries,
                           ["source_term gin_trgm_ops"],
                           prefix: prefix,
                           using: "GIN",
                           name: "#{@ex_lingo_glossary_entries}_source_term_trgm_idx"
                         )
  end

  def down(opts) do
    drop table(@ex_lingo_glossary_entries, prefix: Map.get(opts, :prefix, "public"))
  end
end
