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

  defp up_locales(_opts) do
    create_if_not_exists table(@ex_lingo_locales) do
      add(:iso639_code, :string)
      add(:name, :string)
      add(:native_name, :string)
      add(:family, :string)
      add(:wiki_url, :string)
      add(:colors, {:array, :string})
      add(:plurals_header, :string)
      timestamps()
    end

    create_if_not_exists unique_index(@ex_lingo_locales, [:iso639_code])
  end

  defp up_domains(_opts) do
    create_if_not_exists table(@ex_lingo_domains) do
      add(:name, :string)
      add(:description, :text)
      add(:color, :string, null: false, default: Colors.default_color())
      timestamps()
    end

    create_if_not_exists unique_index(@ex_lingo_domains, [:name])
  end

  defp up_contexts(_opts) do
    create_if_not_exists table(@ex_lingo_contexts) do
      add(:name, :string)
      add(:description, :text)
      add(:color, :string, null: false, default: Colors.default_color())
      timestamps()
    end

    create_if_not_exists unique_index(@ex_lingo_contexts, [:name])
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

    create_if_not_exists table(@ex_lingo_messages) do
      add(:msgid, :text)
      add(:message_type, :gettext_message_type, null: false)
      add(:domain_id, references(@ex_lingo_domains), null: true)
      add(:context_id, references(@ex_lingo_contexts), null: true)
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

    create_if_not_exists unique_index(@ex_lingo_messages, [:context_id, :domain_id, :msgid])
  end

  defp up_singular_translations(_opts) do
    create_if_not_exists table(@ex_lingo_singular_translations) do
      add(:original_text, :text)
      add(:translated_text, :text, null: true)
      add(:locale_id, references(@ex_lingo_locales))
      add(:message_id, references(@ex_lingo_messages))
      timestamps()
    end

    create_if_not_exists unique_index(@ex_lingo_singular_translations, [:locale_id, :message_id])
  end

  defp up_plural_translations(_opts) do
    create_if_not_exists table(@ex_lingo_plural_translations) do
      add(:nplural_index, :integer)
      add(:original_text, :text)
      add(:translated_text, :text, null: true)
      add(:locale_id, references(@ex_lingo_locales))
      add(:message_id, references(@ex_lingo_messages))
      timestamps()
    end

    create_if_not_exists unique_index(@ex_lingo_plural_translations, [
                           :locale_id,
                           :message_id,
                           :nplural_index
                         ])
  end

  defp down_locales(_opts) do
    drop table(@ex_lingo_locales)
  end

  defp down_domains(_opts) do
    drop table(@ex_lingo_domains)
  end

  defp down_contexts(_opts) do
    drop table(@ex_lingo_contexts)
  end

  defp down_messages(_opts) do
    drop table(@ex_lingo_messages)
  end

  defp down_singular_translations(_opts) do
    drop table(@ex_lingo_singular_translations)
  end

  defp down_plural_translations(_opts) do
    drop table(@ex_lingo_plural_translations)
  end
end
