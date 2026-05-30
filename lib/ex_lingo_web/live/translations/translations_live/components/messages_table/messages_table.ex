defmodule ExLingoWeb.Translations.Components.MessagesTable do
  @moduledoc """
  Gettext messages table with inline translation editing.

  Each row shows the source text on the left and embeds an inline translation
  editor (`SingularTranslationForm`/`PluralTranslationForm`) on the right.
  """

  use ExLingoWeb, :live_component

  require Logger
  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]

  alias ExLingoWeb.Translations.{PluralTranslationForm, SingularTranslationForm}

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

  @doc """
  Source text shown in the left column and used as the glossary source.
  """
  def source_text(message), do: message.msgid

  @doc """
  Singular translation (persisted or transient) bound to the inline editor.
  """
  def singular_translation(message, locale) do
    SingularTranslationForm.transient_translation(message, locale, message.singular_translations)
  end

  @doc """
  Plural translations (persisted + transient placeholders) for the inline editor.
  """
  def plural_translations(message, locale) do
    PluralTranslationForm.transient_translations(message, locale, message.plural_translations)
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

  defp notify_parent_refresh do
    send(self(), :refresh_messages)
  end
end
