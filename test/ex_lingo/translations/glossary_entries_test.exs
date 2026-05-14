defmodule ExLingo.Translations.GlossaryEntriesTest do
  use ExLingo.Test.DataCase, async: false

  alias ExLingo.Translations
  alias ExLingo.Translations.GlossaryEntry

  describe "glossary entries" do
    test "creates, updates, lists, and deletes glossary entries" do
      {:ok, entry} =
        Translations.create_glossary_entry(%{
          source_locale: "EN",
          target_locale: "DE",
          source_term: "Certificate",
          target_term: "Ausbildungsnachweis",
          usage_guidance: "Use for training record context."
        })

      assert entry.source_locale == "en"
      assert entry.target_locale == "de"
      assert entry.source_term == "Certificate"

      {:ok, updated} =
        Translations.update_glossary_entry(entry, %{target_term: "Ausbildungsbescheinigung"})

      assert updated.target_term == "Ausbildungsbescheinigung"

      %{entries: entries} = Translations.list_glossary_entries(filter: [source_locale: "en"])
      assert Enum.any?(entries, &(&1.id == entry.id))

      assert {:ok, _deleted} = Translations.delete_glossary_entry(updated)

      assert {:error, :glossary_entry, :not_found} =
               Translations.get_glossary_entry(filter: [id: entry.id])
    end

    test "requires language direction and terms" do
      assert {:error, changeset} = Translations.create_glossary_entry(%{})

      assert %{
               source_locale: ["can't be blank"],
               target_locale: ["can't be blank"],
               source_term: ["can't be blank"],
               target_term: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "migration exposes glossary table columns" do
      {:ok, %{rows: rows}} =
        Repo.query("""
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'ex_lingo_glossary_entries'
        """)

      columns = Enum.map(rows, fn [column] -> column end)

      assert "source_locale" in columns
      assert "target_locale" in columns
      assert "source_term" in columns
      assert "target_term" in columns
      assert "usage_guidance" in columns
    end

    test "changeset supports optional scope references" do
      {:ok, domain} = Translations.create_domain(%{name: "driver_training"})
      {:ok, context} = Translations.create_context(%{name: "certificate_context"})
      {:ok, application_source} = Translations.create_application_source(%{name: "admin"})

      assert {:ok, %GlossaryEntry{} = entry} =
               Translations.create_glossary_entry(%{
                 source_locale: "en",
                 target_locale: "de",
                 source_term: "Certificate",
                 target_term: "Ausbildungsnachweis",
                 domain_id: domain.id,
                 context_id: context.id,
                 application_source_id: application_source.id
               })

      assert entry.domain_id == domain.id
      assert entry.context_id == context.id
      assert entry.application_source_id == application_source.id
    end
  end
end
