defmodule ExLingo.Translations.GlossaryEntries.Services.MatchGlossaryEntries do
  @moduledoc """
  Matches glossary entries relevant for a translation suggestion request.
  """

  alias ExLingo.Translations
  alias ExLingo.Translations.{GlossaryEntry, Message}

  @type params :: %{
          required(:source_locale) => String.t(),
          required(:target_locale) => String.t(),
          required(:source_text) => String.t(),
          optional(:message) => Message.t()
        }

  @spec call(params()) :: [GlossaryEntry.t()]
  def call(
        %{source_locale: source_locale, target_locale: target_locale, source_text: source_text} =
          params
      ) do
    message = Map.get(params, :message)

    [
      filter: [
        source_locale: normalize_locale(source_locale),
        target_locale: normalize_locale(target_locale)
      ],
      preloads: [:domain, :context, :application_source]
    ]
    |> Translations.list_all_glossary_entries()
    |> Enum.filter(&source_term_present?(&1, source_text))
    |> Enum.filter(&scope_matches?(&1, message))
    |> Enum.sort_by(&scope_specificity/1, :desc)
  end

  defp normalize_locale(locale) do
    locale
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end

  defp source_term_present?(%GlossaryEntry{source_term: source_term}, source_text)
       when is_binary(source_term) and is_binary(source_text) do
    source_text
    |> String.downcase()
    |> String.contains?(String.downcase(source_term))
  end

  defp source_term_present?(_, _), do: false

  defp scope_matches?(%GlossaryEntry{} = entry, nil) do
    is_nil(entry.domain_id) and is_nil(entry.context_id) and is_nil(entry.application_source_id)
  end

  defp scope_matches?(%GlossaryEntry{} = entry, %Message{} = message) do
    scope_field_matches?(entry.domain_id, message.domain_id) and
      scope_field_matches?(entry.context_id, message.context_id) and
      scope_field_matches?(entry.application_source_id, message.application_source_id)
  end

  defp scope_field_matches?(nil, _current_id), do: true
  defp scope_field_matches?(scope_id, current_id), do: scope_id == current_id

  defp scope_specificity(%GlossaryEntry{} = entry) do
    [entry.domain_id, entry.context_id, entry.application_source_id]
    |> Enum.count(&(!is_nil(&1)))
  end
end
