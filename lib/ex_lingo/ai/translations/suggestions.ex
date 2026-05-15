defmodule ExLingo.AI.Translations.Suggestions do
  @moduledoc """
  Builds AI suggestion requests and dispatches them to configured provider plugins.
  """

  alias ExLingo.AI.Translations.SuggestionRequest
  alias ExLingo.Translations
  alias ExLingo.Translations.GlossaryEntries.Services.MatchGlossaryEntries
  alias ExLingo.Translations.{Message, PluralTranslation, SingularTranslation}

  @default_source_locale "en"

  def available_providers do
    ExLingo.config().plugins
    |> Enum.map(&elem(&1, 0))
    |> Enum.filter(&provider?/1)
  end

  def provider_options do
    Enum.map(available_providers(), fn provider ->
      %{
        id: provider_id(provider),
        name: provider.provider_name(),
        module: provider,
        models: provider.available_models(),
        default_model: provider.default_model()
      }
    end)
  end

  def provider_id(provider) when is_atom(provider), do: Atom.to_string(provider)

  def provider_from_id(nil), do: List.first(available_providers())

  def provider_from_id(provider_id) do
    Enum.find(available_providers(), &(provider_id(&1) == provider_id))
  end

  def suggest(%Message{} = message, locale, translation, opts \\ []) do
    provider = Keyword.get(opts, :provider) || provider_from_id(Keyword.get(opts, :provider_id))

    cond do
      is_nil(provider) ->
        {:error, :provider_not_configured}

      not provider?(provider) ->
        {:error, {:invalid_provider, provider}}

      true ->
        request = build_request(message, locale, translation, opts)
        provider.suggest_translation(request)
    end
  end

  def build_request(%Message{} = message, locale, translation, opts \\ []) do
    source_locale = Keyword.get(opts, :source_locale, @default_source_locale)
    model = Keyword.get(opts, :model)
    source_text = message.msgid || ""

    glossary_entries =
      MatchGlossaryEntries.call(%{
        source_locale: source_locale,
        target_locale: locale.iso639_code,
        source_text: source_text,
        message: message
      })

    %SuggestionRequest{
      source_locale: source_locale,
      target_locale: locale.iso639_code,
      target_locale_name: locale.name || locale.native_name,
      source_text: source_text,
      message_type: message.message_type,
      message_metadata: message_metadata(message),
      current_translation: current_translation(translation),
      glossary_entries: glossary_entries,
      plural_form_index: plural_form_index(translation),
      plural_examples: plural_examples(locale, translation),
      model: model
    }
  end

  def accept_suggestion(%SingularTranslation{} = translation, suggestion) do
    Translations.update_singular_translation(translation, %{"translated_text" => suggestion})
  end

  def accept_suggestion(%PluralTranslation{} = translation, suggestion) do
    Translations.update_plural_translation(translation, %{"translated_text" => suggestion})
  end

  defp provider?(provider) do
    function_exported?(provider, :suggest_translation, 1) and
      function_exported?(provider, :provider_name, 0) and
      function_exported?(provider, :available_models, 0) and
      function_exported?(provider, :default_model, 0)
  end

  defp message_metadata(message) do
    %{
      message_id: message.id,
      domain_id: message.domain_id,
      context_id: message.context_id,
      application_source_id: message.application_source_id
    }
  end

  defp current_translation(nil), do: %{}

  defp current_translation(%SingularTranslation{} = translation) do
    %{
      id: translation.id,
      original_text: translation.original_text,
      translated_text: translation.translated_text
    }
  end

  defp current_translation(%PluralTranslation{} = translation) do
    %{
      id: translation.id,
      nplural_index: translation.nplural_index,
      original_text: translation.original_text,
      translated_text: translation.translated_text
    }
  end

  defp plural_form_index(%PluralTranslation{nplural_index: index}), do: index
  defp plural_form_index(_translation), do: nil

  defp plural_examples(_locale, %SingularTranslation{}), do: nil
  defp plural_examples(_locale, nil), do: nil

  defp plural_examples(%{plurals_header: plurals_header}, %PluralTranslation{nplural_index: index})
       when is_binary(plurals_header) do
    case Expo.PluralForms.parse(plurals_header) do
      {:ok, forms_struct} ->
        0..100
        |> Enum.group_by(&Expo.PluralForms.index(forms_struct, &1), & &1)
        |> Map.get(index, [])
        |> Enum.join(", ")

      _error ->
        ""
    end
  end

  defp plural_examples(_locale, %PluralTranslation{}), do: ""
end
