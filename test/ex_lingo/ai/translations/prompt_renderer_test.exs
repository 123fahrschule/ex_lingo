defmodule ExLingo.AI.Translations.PromptRendererTest do
  use ExUnit.Case, async: true

  alias ExLingo.AI.Translations.{PromptRenderer, SuggestionRequest}
  alias ExLingo.Translations.GlossaryEntry

  defp request(overrides \\ %{}) do
    base = %SuggestionRequest{
      source_locale: "en",
      target_locale: "de",
      target_locale_name: "German",
      source_text: "Download certificate",
      message_type: :singular,
      message_metadata: %{context: "dashboard button"},
      current_translation: %{translated_text: "Zertifikat laden"},
      glossary_entries: [],
      plural_form_index: nil,
      plural_examples: nil
    }

    struct(base, overrides)
  end

  test "substitutes placeholders with request values" do
    template =
      "From {{source_locale}} to {{target_locale}} ({{target_locale_name}}). " <>
        "Context: {{context}}. Text: {{source_text}}"

    rendered = PromptRenderer.render(template, request())

    assert rendered ==
             "From en to de (German). Context: dashboard button. Text: Download certificate"
  end

  test "renders the current translation and glossary entries" do
    entry = %GlossaryEntry{
      source_term: "certificate",
      target_term: "Zertifikat",
      usage_guidance: "formal"
    }

    template = "Current: {{current_translation}}\nGlossary:\n{{glossary}}"

    rendered = PromptRenderer.render(template, request(%{glossary_entries: [entry]}))

    assert rendered =~ "Current: Zertifikat laden"
    assert rendered =~ "- certificate => Zertifikat (formal)"
  end

  test "shows (none) for empty optional values" do
    # Includes the required placeholders so the guard does not append anything.
    template =
      "{{source_text}} -> {{target_locale}}. " <>
        "Context: {{context}}, glossary: {{glossary}}, current: {{current_translation}}"

    rendered =
      PromptRenderer.render(
        template,
        request(%{message_metadata: %{}, glossary_entries: [], current_translation: %{}})
      )

    assert rendered ==
             "Download certificate -> de. Context: (none), glossary: (none), current: (none)"
  end

  test "appends required fields when the template omits them" do
    rendered = PromptRenderer.render("Just translate, please.", request())

    assert rendered =~ "Just translate, please."
    assert rendered =~ "Source text: Download certificate"
    assert rendered =~ "Target locale: de"
  end

  test "does not duplicate required fields already present in the template" do
    rendered =
      PromptRenderer.render("Translate {{source_text}} into {{target_locale}}.", request())

    assert rendered == "Translate Download certificate into de."
  end

  test "exposes the placeholder and required lists" do
    assert "source_text" in PromptRenderer.placeholders()
    assert "context" in PromptRenderer.placeholders()
    assert PromptRenderer.required_placeholders() == ["source_text", "target_locale"]
  end
end
