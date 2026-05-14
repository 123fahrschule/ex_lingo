defmodule ExLingo.Migrations.Postgresql.V01 do
  @moduledoc """
  ExLingo PostgreSQL V1 Migrations
  """

  use Ecto.Migration

  alias ExLingo.Utils.Colors

  @default_prefix "public"
  @ex_lingo_locales "ex_lingo_locales"
  @ex_lingo_domains "ex_lingo_domains"
  @ex_lingo_contexts "ex_lingo_contexts"
  @ex_lingo_messages "ex_lingo_messages"
  @ex_lingo_singular_translations "ex_lingo_singular_translations"
  @ex_lingo_plural_translations "ex_lingo_plural_translations"

  def up(opts) do
    [
      &up_locales/1,
      &up_contexts/1,
      &up_domains/1,
      &up_messages/1,
      &up_singular_translations/1,
      &up_plural_translations/1
    ]
    |> Enum.each(&apply(&1, [opts]))
  end

  def down(opts) do
    [
      &down_plural_translations/1,
      &down_singular_translations/1,
      &down_messages/1,
      &down_domains/1,
      &down_contexts/1,
      &down_locales/1
    ]
    |> Enum.each(&apply(&1, [opts]))
  end

  defp up_locales(opts) do
    prefix = opts.prefix

    create_if_not_exists table(@ex_lingo_locales, prefix: prefix) do
      add(:iso639_code, :string)
      add(:name, :string)
      add(:native_name, :string)
      add(:family, :string)
      add(:wiki_url, :string)
      add(:colors, {:array, :string})
      add(:plurals_header, :string)
      timestamps()
    end

    create_if_not_exists unique_index(@ex_lingo_locales, [:iso639_code], prefix: prefix)
  end

  defp up_domains(opts) do
    prefix = opts.prefix

    create_if_not_exists table(@ex_lingo_domains, prefix: prefix) do
      add(:name, :string)
      add(:description, :text)
      add(:color, :string, null: false, default: Colors.default_color())
      timestamps()
    end

    create_if_not_exists unique_index(@ex_lingo_domains, [:name], prefix: prefix)
  end

  defp up_contexts(opts) do
    prefix = opts.prefix

    create_if_not_exists table(@ex_lingo_contexts, prefix: prefix) do
      add(:name, :string)
      add(:description, :text)
      add(:color, :string, null: false, default: Colors.default_color())
      timestamps()
    end

    create_if_not_exists unique_index(@ex_lingo_contexts, [:name], prefix: prefix)
  end

  defp up_messages(opts) do
    prefix = Map.get(opts, :prefix, @default_prefix)

    create_if_not_exists_message_type_query = "
      DO $$ BEGIN
          CREATE TYPE gettext_message_type AS ENUM ('singular', 'plural');
      EXCEPTION
          WHEN duplicate_object THEN null;
      END $$
    "

    drop_message_type_query = "DROP TYPE gettext_message_type"
    execute(create_if_not_exists_message_type_query, drop_message_type_query)

    create_if_not_exists table(@ex_lingo_messages, prefix: prefix) do
      add(:msgid, :text)
      add(:message_type, :gettext_message_type, null: false)
      add(:domain_id, references(@ex_lingo_domains, prefix: prefix), null: true)
      add(:context_id, references(@ex_lingo_contexts, prefix: prefix), null: true)
      timestamps()
    end

    execute """
      ALTER TABLE #{prefix}.#{@ex_lingo_messages}
        ADD COLUMN IF NOT EXISTS searchable tsvector
        GENERATED ALWAYS AS (
          setweight(to_tsvector('english', coalesce(msgid, '')), 'A')
        ) STORED;
    """

    execute """
      CREATE INDEX IF NOT EXISTS #{@ex_lingo_messages}_searchable_idx ON #{prefix}.#{@ex_lingo_messages} USING gin(searchable);
    """

    create_if_not_exists unique_index(@ex_lingo_messages, [:context_id, :domain_id, :msgid],
                           prefix: prefix
                         )
  end

  defp up_singular_translations(opts) do
    prefix = opts.prefix

    create_if_not_exists table(@ex_lingo_singular_translations, prefix: prefix) do
      add(:original_text, :text)
      add(:translated_text, :text, null: true)
      add(:locale_id, references(@ex_lingo_locales, prefix: prefix))
      add(:message_id, references(@ex_lingo_messages, prefix: prefix))
      timestamps()
    end

    create_if_not_exists unique_index(@ex_lingo_singular_translations, [:locale_id, :message_id],
                           prefix: prefix
                         )
  end

  defp up_plural_translations(opts) do
    prefix = opts.prefix

    create_if_not_exists table(@ex_lingo_plural_translations, prefix: prefix) do
      add(:nplural_index, :integer)
      add(:original_text, :text)
      add(:translated_text, :text, null: true)
      add(:locale_id, references(@ex_lingo_locales, prefix: prefix))
      add(:message_id, references(@ex_lingo_messages, prefix: prefix))
      timestamps()
    end

    create_if_not_exists unique_index(
                           @ex_lingo_plural_translations,
                           [
                             :locale_id,
                             :message_id,
                             :nplural_index
                           ], prefix: prefix)
  end

  defp down_locales(opts) do
    drop table(@ex_lingo_locales, prefix: opts.prefix)
  end

  defp down_domains(opts) do
    drop table(@ex_lingo_domains, prefix: opts.prefix)
  end

  defp down_contexts(opts) do
    drop table(@ex_lingo_contexts, prefix: opts.prefix)
  end

  defp down_messages(opts) do
    drop table(@ex_lingo_messages, prefix: opts.prefix)
  end

  defp down_singular_translations(opts) do
    drop table(@ex_lingo_singular_translations, prefix: opts.prefix)
  end

  defp down_plural_translations(opts) do
    drop table(@ex_lingo_plural_translations, prefix: opts.prefix)
  end
end
