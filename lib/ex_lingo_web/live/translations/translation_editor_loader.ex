defmodule ExLingoWeb.Translations.TranslationEditorLoader do
  @moduledoc false

  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]

  alias ExLingo.Translations
  alias ExLingo.Translations.Message

  def load(locale_id, message_id) do
    with {:ok, locale} <- get_locale(locale_id),
         {:ok, message} <- get_message(message_id),
         {:ok, translations} <- get_translations(message, locale) do
      {:ok,
       %{
         locale: locale,
         message: message,
         translations: translations,
         possible_duplicate_candidates: possible_duplicate_candidates(locale, message)
       }}
    end
  end

  defp get_translations(%Message{message_type: :singular} = message, locale) do
    case Translations.get_singular_translation(
           filter: [
             locale_id: locale.id,
             message_id: message.id
           ]
         ) do
      {:ok, translations} ->
        {:ok, translations}

      {:error, _, _} ->
        Translations.create_singular_translation(%{
          original_text: nil,
          translated_text: nil,
          locale_id: locale.id,
          message_id: message.id
        })
    end
  end

  defp get_translations(%Message{message_type: :plural} = message, locale) do
    case Translations.list_plural_translations(
           filter: [
             locale_id: locale.id,
             message_id: message.id
           ]
         ) do
      %{entries: entries} when entries != [] ->
        {:ok, entries}

      _ ->
        with {:ok, %{nplurals: plurals_count}} <- Expo.PluralForms.parse(locale.plurals_header) do
          indices = if plurals_count > 0, do: 0..(plurals_count - 1), else: []

          translations =
            indices
            |> Enum.map(&create_plural_translation(&1, locale, message))
            |> Enum.reject(&is_nil/1)

          {:ok, translations}
        end
    end
  end

  defp create_plural_translation(index, locale, message) do
    case Translations.create_plural_translation(%{
           nplural_index: index,
           original_text: nil,
           translated_text: nil,
           locale_id: locale.id,
           message_id: message.id
         }) do
      {:ok, translation} -> translation
      _error -> nil
    end
  end

  defp get_locale(locale_id) when is_integer(locale_id) do
    Translations.get_locale(filter: [id: locale_id])
  end

  defp get_locale(locale_id) do
    case parse_id_filter(locale_id) do
      {:ok, id} -> Translations.get_locale(filter: [id: id])
      _invalid -> {:error, :id, :invalid}
    end
  end

  defp get_message(message_id) do
    case parse_id_filter(message_id) do
      {:ok, id} ->
        Translations.get_message(
          filter: [id: id],
          preloads: [:domain, :context, :application_source]
        )

      _invalid ->
        {:error, :id, :invalid}
    end
  end

  defp possible_duplicate_candidates(locale, message) do
    Translations.possible_duplicate_translations_for_message(
      locale_id: locale.id,
      message_id: message.id
    )
  end
end
