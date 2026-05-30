defmodule ExLingoWeb.Translations.Components.MessagesTable do
  @moduledoc """
  Gettext messages table with inline translation editing.

  Each row shows the source text on the left and embeds an inline translation
  editor (`SingularTranslationForm`/`PluralTranslationForm`) on the right, plus
  an expandable image panel for uploading screenshots/mockups to S3 as visual
  translation context.
  """

  use ExLingoWeb, :live_component

  require Logger
  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]

  import ExLingoWeb.Translations.MessageMetadata,
    only: [source_references: 1, source_reference_label: 1]

  alias ExLingo.Storage.S3
  alias ExLingo.Translations
  alias ExLingoWeb.Translations.{PluralTranslationForm, SingularTranslationForm}

  @accept ~w(.png .jpg .jpeg .webp)
  @max_entries 10
  @max_file_size 5 * 1024 * 1024

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:open_message_id, fn -> nil end)
      |> assign_new(:open_images, fn -> [] end)
      |> maybe_allow_upload()
      |> assign(:s3_ready?, S3.configured?())
      |> assign_image_counts()

    {:ok, socket}
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

  def handle_event("toggle_images", %{"message-id" => message_id}, socket) do
    case parse_id_filter(message_id) do
      {:ok, id} ->
        if socket.assigns.open_message_id == id do
          {:noreply, assign(socket, open_message_id: nil, open_images: [])}
        else
          {:noreply,
           socket
           |> assign(:open_message_id, id)
           |> load_open_images(id)}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("close_images", _params, socket) do
    {:noreply, assign(socket, open_message_id: nil, open_images: [])}
  end

  # Auto-upload form change; entries upload immediately, so nothing to do here.
  def handle_event("validate_images", _params, socket), do: {:noreply, socket}

  def handle_event("delete_image", %{"image-id" => image_id}, socket) do
    with {:ok, image_id} <- parse_id_filter(image_id),
         {:ok, image} <- Translations.get_message_image(image_id),
         {:ok, _} <- S3.delete(image.s3_key),
         {:ok, _} <- Translations.delete_message_image(image_id) do
      {:noreply,
       socket
       |> load_open_images(socket.assigns.open_message_id)
       |> assign_image_counts()}
    else
      error ->
        Logger.error("Failed to delete message image: #{inspect(error)}")
        {:noreply, put_flash(socket, :error, t("Could not delete the image."))}
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

  def image_count(message, image_counts) when is_map(image_counts) do
    Map.get(image_counts, message.id, 0)
  end

  def image_count(_message, _image_counts), do: 0

  def column_count(application_sources_empty?) do
    # Source, Translation, [Application], Actions
    if application_sources_empty?, do: 3, else: 4
  end

  def upload_error_to_string(:too_large), do: t("File is too large (max 5 MB).")
  def upload_error_to_string(:too_many_files), do: t("Too many files (max 10).")
  def upload_error_to_string(:not_accepted), do: t("Unsupported file type.")
  def upload_error_to_string(_error), do: t("Upload error.")

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

  defp assign_image_counts(socket) do
    counts =
      socket.assigns.messages
      |> Enum.map(& &1.id)
      |> Translations.message_image_counts()

    assign(socket, :image_counts, counts)
  end

  defp load_open_images(socket, nil), do: assign(socket, :open_images, [])

  defp load_open_images(socket, message_id) do
    images =
      message_id
      |> Translations.list_message_images()
      |> Enum.map(fn image -> %{image: image, url: presigned_or_nil(image.s3_key)} end)

    assign(socket, :open_images, images)
  end

  defp presigned_or_nil(key) do
    case S3.presigned_url(key) do
      {:ok, url} -> url
      _error -> nil
    end
  end

  defp maybe_allow_upload(socket) do
    if uploads_configured?(socket) do
      socket
    else
      allow_upload(socket, :message_images,
        accept: @accept,
        max_entries: @max_entries,
        max_file_size: @max_file_size,
        auto_upload: true,
        external: &presign_upload/2,
        progress: &handle_progress/3
      )
    end
  end

  defp uploads_configured?(socket) do
    match?(%{uploads: %{message_images: _}}, socket.assigns)
  end

  defp presign_upload(entry, socket) do
    key = S3.object_key(socket.assigns.open_message_id, entry.client_name)

    case S3.presigned_url(key, method: :put, expires_in: 3600) do
      {:ok, url} ->
        {:ok, %{uploader: "S3", key: key, url: url}, socket}

      {:error, reason} ->
        Logger.error("Failed to presign S3 upload: #{inspect(reason)}")
        {:error, %{}, socket}
    end
  end

  defp handle_progress(:message_images, entry, socket) do
    if entry.done? do
      message_id = socket.assigns.open_message_id

      consume_uploaded_entry(socket, entry, fn %{key: key} ->
        {:ok, _image} =
          Translations.create_message_image(message_id, %{
            s3_key: key,
            content_type: entry.client_type,
            byte_size: entry.client_size
          })

        {:ok, key}
      end)

      {:noreply,
       socket
       |> load_open_images(message_id)
       |> assign_image_counts()}
    else
      {:noreply, socket}
    end
  end
end
