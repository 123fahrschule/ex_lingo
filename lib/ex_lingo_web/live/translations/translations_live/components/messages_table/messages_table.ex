defmodule ExLingoWeb.Translations.Components.MessagesTable do
  @moduledoc """
  Gettext messages table component
  """

  use ExLingoWeb, :live_component

  require Logger
  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]

  alias ExLingo.Translations.{Message, SingularTranslation}

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def message_stale?(message, stale_message_ids) do
    MapSet.member?(stale_message_ids, message.id)
  end

  def handle_event("delete_stale", %{"message-id" => message_id}, socket) do
    with {:ok, message_id} <- parse_id_filter(message_id),
         {:ok, _stats} <- ExLingo.Translations.delete_message(message_id) do
      send(self(), :refresh_messages)
      {:noreply, socket}
    else
      error ->
        Logger.error("Failed to delete stale message: #{inspect(error)}")
        {:noreply, put_flash(socket, :error, t("Failed to delete stale message."))}
    end
  end

  def handle_event(
        "merge_messages",
        %{"from-id" => from_id, "to-id" => to_id},
        socket
      ) do
    with {:ok, from_message_id} <- parse_id_filter(from_id),
         {:ok, to_message_id} <- parse_id_filter(to_id),
         {:ok, _target_message} <-
           ExLingo.Translations.merge_messages(from_message_id, to_message_id) do
      notify_parent_refresh()
      {:noreply, socket}
    else
      error ->
        Logger.error("Failed to merge messages: #{inspect(error)}")
        {:noreply, put_flash(socket, :error, t("Failed to merge messages."))}
    end
  end

  def translated?(%Message{message_type: :singular} = message, locale, source) do
    case Enum.find(message.singular_translations, &(&1.locale_id == locale.id)) do
      nil ->
        false

      %SingularTranslation{} = translation ->
        case get_in(translation, [Access.key!(source)]) do
          nil -> false
          "" -> false
          _text -> true
        end
    end
  end

  def translated?(%Message{message_type: :plural} = message, locale, source) do
    case Enum.filter(message.plural_translations, &(&1.locale_id == locale.id)) do
      [] ->
        false

      translations ->
        Enum.all?(translations, &plural_form_translated?(&1, source))
    end
  end

  def highlighted_message?(message, highlighted_message_id) do
    not is_nil(highlighted_message_id) and
      to_string(message.id) == to_string(highlighted_message_id)
  end

  def possible_duplicate?(message, summaries) when is_map(summaries) do
    Map.has_key?(summaries, message.id)
  end

  def possible_duplicate?(_message, _summaries), do: false

  def possible_duplicate_title(message, summaries) when is_map(summaries) do
    case Map.get(summaries, message.id) do
      %{count: count, highest_confidence: confidence} ->
        "#{t("Possible duplicate")}: #{count} · #{confidence_label(confidence)}"

      _summary ->
        t("Possible duplicate")
    end
  end

  def possible_duplicate_title(_message, _summaries), do: t("Possible duplicate")

  defp confidence_label(:high), do: t("High confidence")
  defp confidence_label(:medium), do: t("Medium confidence")
  defp confidence_label(:low), do: t("Low confidence")
  defp confidence_label(_confidence), do: t("Possible duplicate")

  defp plural_form_translated?(translation, source) do
    case get_in(translation, [Access.key!(source)]) do
      nil ->
        false

      "" ->
        false

      _text ->
        true
    end
  end

  def translated_text(assigns, %Message{message_type: :singular} = message),
    do: translated_singular_text(assigns, message, :translated_text)

  def translated_text(assigns, %Message{message_type: :plural} = message),
    do: translated_plural_text(assigns, message, :translated_text)

  def original_text(assigns, %Message{message_type: :singular} = message),
    do: translated_singular_text(assigns, message, :original_text)

  def original_text(assigns, %Message{message_type: :plural} = message),
    do: translated_plural_text(assigns, message, :original_text)

  def translated_singular_text(assigns, message, source) do
    case Enum.find(message.singular_translations, &(&1.locale_id == assigns.locale.id)) do
      nil ->
        "Missing"

      %SingularTranslation{} = translation ->
        case get_in(translation, [Access.key!(source)]) do
          nil -> "Missing"
          "" -> "Missing"
          text -> truncate_translation(text)
        end
    end
  end

  def translated_plural_text(assigns, message, source) do
    translations =
      case Enum.filter(message.plural_translations, &(&1.locale_id == assigns.locale.id)) do
        [] ->
          []

        translations ->
          translations
          |> Enum.map(fn translation ->
            text = get_plural_form_text(translation, source)

            %{index: translation.nplural_index, text: text}
          end)
      end

    assigns = assign(assigns, :translations, translations)

    if translations != [] do
      ~H"""
        <div>
          <%= for plural_translation <- Enum.sort_by(@translations, & &1[:index], :asc) do %>
            <div class={if plural_translation[:text] != "Missing", do: "text-success-500", else: "text-error-500"}>
              Plural form <%= plural_translation[:index] %>: <%= plural_translation[:text] %>
            </div>
          <% end %>
        </div>
      """
    else
      "Missing"
    end
  end

  defp get_plural_form_text(translation, source) do
    case get_in(translation, [Access.key!(source)]) do
      nil ->
        "Missing"

      "" ->
        "Missing"

      text ->
        truncate_translation(text)
    end
  end

  defp truncate_translation(text) do
    if String.length(text) > 45, do: String.slice(text, 0..45) <> "... ", else: text
  end

  defp notify_parent_refresh do
    send(self(), :refresh_messages)
  end
end
