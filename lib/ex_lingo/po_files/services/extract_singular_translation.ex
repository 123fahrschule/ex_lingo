defmodule ExLingo.PoFiles.Services.ExtractSingularTranslation do
  @moduledoc """
  Service for extracting singular messages and translations from .po files
  """

  alias ExLingo.PoFiles.Services.ExtractMessage
  alias ExLingo.Repo
  alias ExLingo.Translations
  alias ExLingo.Translations.Locale.Services.CreateLocaleFromIsoCode

  def call(attrs) do
    repo = Repo.get_repo()

    repo.transaction(fn ->
      with attrs <- Map.put(attrs, :message_type, :singular),
           {:ok, message} <- ExtractMessage.call(attrs),
           {:ok, locale} <- get_or_create_locale(attrs[:locale_name]),
           {:ok, translation} <- create_or_update_singular_translation(attrs, message, locale) do
        translation
      else
        {:error, reason} -> repo.rollback(reason)
        error -> repo.rollback(error)
      end
    end)
  end

  defp get_or_create_locale(iso639_code) do
    case Translations.get_locale(filter: [iso639_code: iso639_code]) do
      {:ok, locale} -> {:ok, locale}
      {:error, :locale, :not_found} -> CreateLocaleFromIsoCode.call(iso639_code, nil)
    end
  end

  defp create_or_update_singular_translation(attrs, message, locale) do
    case Translations.get_singular_translation(
           filter: [message_id: message.id, locale_id: locale.id]
         ) do
      {:ok, translation} ->
        attrs = seed_translated_text(attrs, translation.translated_text)
        Translations.update_singular_translation(translation, attrs)

      {:error, :singular_translation, :not_found} ->
        attrs
        |> seed_translated_text(nil)
        |> Map.put(:message_id, message.id)
        |> Map.put(:locale_id, locale.id)
        |> Translations.create_singular_translation()
    end
  end

  defp seed_translated_text(attrs, existing_translation) do
    original_text = Map.get(attrs, :original_text)

    if blank?(existing_translation) and present?(original_text) do
      Map.put(attrs, :translated_text, original_text)
    else
      attrs
    end
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
  defp blank?(value), do: is_nil(value) or (is_binary(value) and String.trim(value) == "")
end
