defmodule ExLingoWeb.Translations.PossibleDuplicateComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ExLingo.Translations.PossibleDuplicateTranslations.{Candidate, Occurrence}
  alias ExLingo.Translations.{Locale, Message, SingularTranslation}
  alias ExLingoWeb.Translations.Components.MessagesTable
  alias ExLingoWeb.Translations.PossibleDuplicateComponents
  alias ExLingoWeb.Translations.SingularTranslationForm

  test "renders duplicate candidate details" do
    html =
      render_component(&PossibleDuplicateComponents.possible_duplicate_details/1,
        candidates: [candidate()],
        current_message_id: 1
      )

    assert html =~ "Possible duplicate"
    assert html =~ "Same source and translation"
    assert html =~ "High confidence"
    assert html =~ "Abbrechen"
    assert html =~ "lib/app/modal.ex:12"
    assert html =~ "Copy AI instructions"
  end

  test "builds cautious AI cleanup instructions" do
    instruction = PossibleDuplicateComponents.ai_cleanup_instruction(candidate())

    assert instruction =~ "Repository der Anwendung"
    assert instruction =~ "Semantik wirklich vollständig gleich"
    assert instruction =~ "Gleiche Zielübersetzungen allein reichen nicht aus"
    refute instruction =~ "ExLingo"
    refute instruction =~ "Message-ID"
    refute instruction =~ "Translation-ID"
    assert instruction =~ "lib/app/modal.ex:12"
    assert instruction =~ "nicht aufgezeichnet; suche nach dem Quelltext"
    assert instruction =~ ~s("Abbrechen")
  end

  test "renders vertical spacing between duplicate groups" do
    second_candidate = %Candidate{candidate() | id: "same-source-second", target_text: "Ablehnen"}

    html =
      render_component(&PossibleDuplicateComponents.possible_duplicate_details/1,
        candidates: [candidate(), second_candidate],
        current_message_id: 1
      )

    assert html =~ "margin-bottom: 1.5rem;"
  end

  test "renders padding and spacing inside related duplicate messages" do
    html =
      render_component(&PossibleDuplicateComponents.possible_duplicate_details/1,
        candidates: [candidate()],
        current_message_id: 1
      )

    assert html =~ "padding: 1rem;"
    assert html =~ "margin-bottom: 1rem;"
  end

  test "renders duplicate badge in messages table" do
    message = %Message{
      id: 1,
      msgid: "Cancel",
      message_type: :singular,
      domain: nil,
      context: nil,
      application_source: nil,
      singular_translations: [
        %SingularTranslation{
          id: 1,
          message_id: 1,
          locale_id: 1,
          original_text: "Cancel",
          translated_text: "Abbrechen"
        }
      ],
      plural_translations: []
    }

    html =
      render_component(&MessagesTable.render/1,
        id: "messages-table",
        myself: nil,
        messages: [message],
        filters: %{},
        sort: %{},
        locale: %Locale{id: 1, native_name: "Deutsch"},
        application_sources_empty?: true,
        stale_message_ids: MapSet.new(),
        fuzzy_matches: %{},
        possible_duplicate_summaries: %{1 => %{count: 1, highest_confidence: :high}},
        highlighted_message_id: nil
      )

    assert html =~ "Duplicate?"
  end

  test "renders duplicate details inside singular translation editor" do
    message = %Message{
      id: 1,
      msgid: "Cancel",
      message_type: :singular,
      domain: nil,
      context: nil,
      application_source: nil
    }

    translation = %SingularTranslation{
      id: 1,
      message_id: 1,
      locale_id: 1,
      original_text: "Cancel",
      translated_text: "Abbrechen"
    }

    html =
      render_component(&SingularTranslationForm.render/1,
        id: "singular-form",
        myself: nil,
        mode: :sheet,
        translation: translation,
        message: message,
        locale: %Locale{id: 1, native_name: "Deutsch"},
        filters: %{},
        form: %{"original_text" => "Cancel", "translated_text" => "Abbrechen"},
        possible_duplicate_candidates: [candidate()]
      )

    assert html =~ "Possible duplicate"
    assert html =~ "This translation may be shared with other active messages."
  end

  defp candidate do
    %Candidate{
      id: "same-source",
      reason: :same_source_same_target_different_scope,
      confidence: :high,
      translation_type: :singular,
      target_text: "Abbrechen",
      source_text: "Cancel",
      source_texts: ["Cancel"],
      occurrence_count: 2,
      message_ids: [1, 2],
      occurrences: [
        %Occurrence{
          message_id: 1,
          translation_id: 1,
          translation_type: :singular,
          source_text: "Cancel",
          target_text: "Abbrechen",
          source_references: [%{"file" => "lib/app/modal.ex", "line" => 12}]
        },
        %Occurrence{
          message_id: 2,
          translation_id: 2,
          translation_type: :singular,
          source_text: "Cancel",
          target_text: "Abbrechen",
          source_references: []
        }
      ]
    }
  end
end
