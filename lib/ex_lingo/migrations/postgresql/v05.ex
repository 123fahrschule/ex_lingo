defmodule ExLingo.Migrations.Postgresql.V05 do
  @moduledoc """
  ExLingo PostgreSQL V5 Migrations
  """

  use Ecto.Migration

  @ex_lingo_glossary_entries "ex_lingo_glossary_entries"
  @ex_lingo_domains "ex_lingo_domains"
  @ex_lingo_contexts "ex_lingo_contexts"
  @ex_lingo_application_sources "ex_lingo_application_sources"

  def up(opts) do
    prefix = opts.prefix

    create_if_not_exists table(@ex_lingo_glossary_entries, prefix: prefix) do
      add(:source_locale, :string, null: false)
      add(:target_locale, :string, null: false)
      add(:source_term, :text, null: false)
      add(:target_term, :text, null: false)
      add(:usage_guidance, :text)
      add(:domain_id, references(@ex_lingo_domains, prefix: prefix), null: true)
      add(:context_id, references(@ex_lingo_contexts, prefix: prefix), null: true)

      add(:application_source_id, references(@ex_lingo_application_sources, prefix: prefix),
        null: true
      )

      timestamps()
    end

    create_if_not_exists index(@ex_lingo_glossary_entries, [:source_locale, :target_locale],
                           prefix: prefix
                         )

    create_if_not_exists index(@ex_lingo_glossary_entries, [:domain_id], prefix: prefix)
    create_if_not_exists index(@ex_lingo_glossary_entries, [:context_id], prefix: prefix)

    create_if_not_exists index(@ex_lingo_glossary_entries, [:application_source_id],
                           prefix: prefix
                         )
  end

  def down(opts) do
    drop table(@ex_lingo_glossary_entries, prefix: opts.prefix)
  end
end
