defmodule ExLingo.Translations.PossibleDuplicateTranslationsTest do
  use ExLingo.Test.DataCase, async: false

  alias ExLingo.Translations

  setup do
    ExLingo.Cache.delete_all()

    {:ok, locale} =
      Translations.create_locale(%{
        iso639_code: "de",
        name: "German",
        native_name: "Deutsch",
        plurals_header: "nplurals=2; plural=(n != 1);"
      })

    {:ok, domain} = Translations.create_domain(%{name: "default"})

    %{locale: locale, domain: domain, context: "default"}
  end

  test "detects high-confidence duplicates for same source and target across scopes", %{
    locale: locale,
    domain: domain
  } do
    first =
      create_singular(locale, domain, "modal", "Cancel", "Abbrechen",
        refs: [%{"file" => "lib/app/modal.ex", "line" => 12}]
      )

    second =
      create_singular(locale, domain, "form", "Cancel", "Abbrechen",
        refs: [%{"file" => "lib/app/form.ex", "line" => 20}]
      )

    [candidate] = Translations.list_possible_duplicate_translations(locale_id: locale.id)

    assert candidate.reason == :same_source_same_target_different_scope
    assert candidate.confidence == :high
    assert candidate.translation_type == :singular
    assert candidate.source_text == "Cancel"
    assert candidate.target_text == "Abbrechen"
    assert candidate.message_ids == Enum.sort([first.id, second.id])
    assert Enum.any?(candidate.occurrences, &(&1.source_references != []))

    summaries =
      Translations.possible_duplicate_translation_summaries(
        locale_id: locale.id,
        message_ids: [first.id]
      )

    assert %{count: 1, highest_confidence: :high} = Map.fetch!(summaries, first.id)
    refute Map.has_key?(summaries, second.id)
  end

  test "detects target-only duplicates for short source strings with compatible placeholders", %{
    locale: locale,
    domain: domain,
    context: context
  } do
    cancel = create_singular(locale, domain, context, "Cancel", "Abbrechen")
    abort = create_singular(locale, domain, context, "Abort", "Abbrechen")

    [candidate] = Translations.list_possible_duplicate_translations(locale_id: locale.id)

    assert candidate.reason == :same_target_different_source
    assert candidate.confidence == :low
    assert candidate.source_text == nil
    assert candidate.source_texts == ["Abort", "Cancel"]
    assert candidate.message_ids == Enum.sort([cancel.id, abort.id])
  end

  test "detects loose source variants", %{locale: locale, domain: domain, context: context} do
    create_singular(locale, domain, context, " Cancel ", "Abbrechen")
    create_singular(locale, domain, context, "cancel.", "Abbrechen")

    [candidate] = Translations.list_possible_duplicate_translations(locale_id: locale.id)

    assert candidate.reason == :near_source_variant_same_target
    assert candidate.confidence == :medium
    assert candidate.target_text == "Abbrechen"
    assert candidate.source_texts == [" Cancel ", "cancel."]
  end

  test "excludes messages without effective translated text", %{
    locale: locale,
    domain: domain,
    context: context
  } do
    create_singular(locale, domain, context, "Cancel", nil, original_text: nil)
    create_singular(locale, domain, context, "Abort", "", original_text: " ")

    assert Translations.list_possible_duplicate_translations(locale_id: locale.id) == []
  end

  test "excludes placeholder mismatches from duplicate groups", %{
    locale: locale,
    domain: domain,
    context: context
  } do
    create_singular(locale, domain, context, "Delete %{name}", "Löschen")
    create_singular(locale, domain, context, "Delete %{count}", "Löschen")

    assert Translations.list_possible_duplicate_translations(locale_id: locale.id) == []
  end

  test "does not group plural translations with different plural indexes", %{
    locale: locale,
    domain: domain,
    context: context
  } do
    create_plural(locale, domain, context, "Item", 0, "Artikel")
    create_plural(locale, domain, context, "Items", 1, "Artikel")

    assert Translations.list_possible_duplicate_translations(locale_id: locale.id) == []
  end

  defp create_singular(locale, domain, context, msgid, translated_text, opts \\ []) do
    {:ok, message} =
      Translations.create_message(%{
        msgid: msgid,
        message_type: :singular,
        domain_id: domain.id,
        context: context,
        source_references: Keyword.get(opts, :refs, [])
      })

    {:ok, _translation} =
      Translations.create_singular_translation(%{
        message_id: message.id,
        locale_id: locale.id,
        original_text: Keyword.get(opts, :original_text, msgid),
        translated_text: translated_text
      })

    message
  end

  defp create_plural(locale, domain, context, msgid, nplural_index, translated_text) do
    {:ok, message} =
      Translations.create_message(%{
        msgid: msgid,
        message_type: :plural,
        domain_id: domain.id,
        context: context
      })

    {:ok, _translation} =
      Translations.create_plural_translation(%{
        message_id: message.id,
        locale_id: locale.id,
        nplural_index: nplural_index,
        original_text: msgid,
        translated_text: translated_text
      })

    message
  end
end
