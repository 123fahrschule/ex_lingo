defmodule ExLingo.PoFiles.Services.ExtractPluralTranslation do
  @moduledoc """
  Service for extracting plural messages and translations from .po files
  """

  alias ExLingo.PoFiles.Services.ExtractMessage
  alias ExLingo.Repo
  alias ExLingo.Translations
  alias ExLingo.Translations.Locale.Services.CreateLocaleFromIsoCode

  def call(attrs) do
    repo = Repo.get_repo()

    repo.transaction(fn ->
      with attrs <- Map.put(attrs, :message_type, :plural),
           {:ok, message} <- ExtractMessage.call(attrs),
           {:ok, locale} <- get_or_create_locale(attrs[:locale_name], attrs[:plurals_header]),
           {:ok, translations} <- create_or_update_plural_translations(attrs, message, locale) do
        translations
      else
        {:error, reason} -> repo.rollback(reason)
        error -> repo.rollback(error)
      end
    end)
  end

  defp get_or_create_locale(iso639_code, plurals_header) do
    case Translations.get_locale(filter: [iso639_code: iso639_code]) do
      {:ok, locale} -> Translations.update_locale(locale, %{plurals_header: plurals_header})
      {:error, :locale, :not_found} -> CreateLocaleFromIsoCode.call(iso639_code, plurals_header)
    end
  end

  defp create_or_update_plural_translations(attrs, message, locale) do
    Enum.map(attrs[:plurals_map], fn {index, [original_text]} ->
      case Translations.get_plural_translation(
             filter: [message_id: message.id, locale_id: locale.id, nplural_index: index]
           ) do
        {:ok, translation} ->
          attrs
          |> Map.put(:original_text, original_text)
          |> seed_translated_text(original_text, translation.translated_text)
          |> then(&Translations.update_plural_translation(translation, &1))

        {:error, :plural_translation, :not_found} ->
          attrs
          |> Map.put(:nplural_index, index)
          |> Map.put(:original_text, original_text)
          |> seed_translated_text(original_text, nil)
          |> Map.put(:message_id, message.id)
          |> Map.put(:locale_id, locale.id)
          |> Translations.create_plural_translation()
      end
    end)
    |> Enum.all?(&(elem(&1, 0) == :ok))
    |> case do
      true -> {:ok, []}
      false -> {:error, nil}
    end
  end

  defp seed_translated_text(attrs, original_text, existing_translation) do
    if blank?(existing_translation) and present?(original_text) do
      Map.put(attrs, :translated_text, original_text)
    else
      attrs
    end
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
  defp blank?(value), do: is_nil(value) or (is_binary(value) and String.trim(value) == "")
end
