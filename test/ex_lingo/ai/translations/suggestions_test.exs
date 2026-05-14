defmodule ExLingo.AI.Translations.SuggestionsTest do
  use ExLingo.Test.DataCase, async: false

  alias ExLingo.AI.Translations.{SuggestionRequest, Suggestions}
  alias ExLingo.Translations

  defmodule SuccessProvider do
    def provider_name, do: "Success"
    def available_models, do: ["test-model"]
    def default_model, do: "test-model"

    def suggest_translation(%SuggestionRequest{} = request) do
      assert request.source_text == "Download certificate"
      {:ok, "Ausbildungsnachweis herunterladen"}
    end
  end

  defmodule ErrorProvider do
    def provider_name, do: "Error"
    def available_models, do: ["test-model"]
    def default_model, do: "test-model"
    def suggest_translation(%SuggestionRequest{}), do: {:error, :failed}
  end

  setup do
    {:ok, locale} =
      Translations.create_locale(%{
        iso639_code: "de",
        name: "German",
        native_name: "Deutsch",
        plurals_header: "nplurals=2; plural=(n != 1);"
      })

    {:ok, message} =
      Translations.create_message(%{
        msgid: "Download certificate",
        message_type: :singular
      })

    {:ok, translation} =
      Translations.create_singular_translation(%{
        message_id: message.id,
        locale_id: locale.id,
        original_text: nil,
        translated_text: nil
      })

    {:ok, glossary_entry} =
      Translations.create_glossary_entry(%{
        source_locale: "en",
        target_locale: "de",
        source_term: "certificate",
        target_term: "Ausbildungsnachweis"
      })

    %{
      locale: locale,
      message: message,
      translation: translation,
      glossary_entry: glossary_entry
    }
  end

  test "builds normalized request with matching glossary entries", %{
    locale: locale,
    message: message,
    translation: translation,
    glossary_entry: glossary_entry
  } do
    request =
      Suggestions.build_request(message, locale, translation,
        source_locale: "en",
        model: "test-model"
      )

    assert request.source_locale == "en"
    assert request.target_locale == "de"
    assert request.source_text == message.msgid
    assert request.model == "test-model"
    assert Enum.map(request.glossary_entries, & &1.id) == [glossary_entry.id]
  end

  test "dispatches to explicit provider", %{
    locale: locale,
    message: message,
    translation: translation
  } do
    assert {:ok, "Ausbildungsnachweis herunterladen"} =
             Suggestions.suggest(message, locale, translation, provider: SuccessProvider)
  end

  test "returns provider errors", %{locale: locale, message: message, translation: translation} do
    assert {:error, :failed} =
             Suggestions.suggest(message, locale, translation, provider: ErrorProvider)
  end

  test "accepts suggestion without provider metadata", %{translation: translation} do
    assert {:ok, updated} = Suggestions.accept_suggestion(translation, "Ausbildungsnachweis")
    assert updated.translated_text == "Ausbildungsnachweis"
  end
end
