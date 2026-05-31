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
      source_text: source_text,
      message: message,
      preloads: [:domain]
    ]
    |> Translations.list_matching_glossary_entries()
    |> Enum.sort_by(&scope_specificity/1, :desc)
  end

  defp normalize_locale(locale) do
    locale
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end

  defp scope_specificity(%GlossaryEntry{} = entry) do
    if is_nil(entry.domain_id), do: 0, else: 1
  end
end
