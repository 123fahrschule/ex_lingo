defmodule ExLingo.Translations.Messages do
  @moduledoc """
  ExLingo Messages subcontext
  """

  require Logger

  alias ExLingo.Repo
  alias ExLingo.Storage.S3

  alias ExLingo.Translations.Message
  alias ExLingo.Translations.{MessageImage, SingularTranslation, PluralTranslation}

  alias ExLingo.Translations.Messages.Finders.{GetMessage, ListAllMessages, ListMessages}

  def list_messages(params \\ []) do
    ListMessages.find(params)
  end

  def list_all_messages(params \\ []) do
    ListAllMessages.find(params)
  end

  def get_message(params \\ []) do
    GetMessage.find(params)
  end

  def get_messages_count do
    Repo.get_repo().aggregate(Message, :count, Repo.opts())
  end

  # MESSAGE IMAGES

  @doc "Lists a message's images, oldest first."
  def list_images(message_id) do
    import Ecto.Query

    MessageImage
    |> where([image], image.message_id == ^message_id)
    |> order_by([image], asc: image.inserted_at, asc: image.id)
    |> Repo.get_repo().all(Repo.opts())
  end

  @doc "Fetches a single image by id."
  def get_image(image_id) do
    case Repo.get_repo().get(MessageImage, image_id, Repo.opts()) do
      %MessageImage{} = image -> {:ok, image}
      nil -> {:error, :not_found}
    end
  end

  @doc "Creates an image row for a message after the binary was stored in S3."
  def create_image(message_id, attrs, opts \\ []) do
    attrs = attrs |> Map.new() |> Map.put(:message_id, message_id)

    %MessageImage{}
    |> MessageImage.changeset(attrs)
    |> Repo.get_repo().insert(Repo.opts(opts))
  end

  @doc "Deletes an image row. The S3 object must be removed separately."
  def delete_image(image_id, opts \\ []) do
    with {:ok, image} <- get_image(image_id) do
      Repo.get_repo().delete(image, Repo.opts(opts))
    end
  end

  @doc """
  Returns a `%{message_id => count}` map for the given message ids, so the
  translation list can show an image badge per row without an N+1 query.
  """
  def image_counts(message_ids) when is_list(message_ids) do
    import Ecto.Query

    case message_ids do
      [] ->
        %{}

      ids ->
        MessageImage
        |> where([image], image.message_id in ^ids)
        |> group_by([image], image.message_id)
        |> select([image], {image.message_id, count(image.id)})
        |> Repo.get_repo().all(Repo.opts())
        |> Map.new()
    end
  end

  @doc "Reassigns all images from one message to another (used when merging)."
  def move_images(from_message_id, to_message_id, opts \\ []) do
    import Ecto.Query

    MessageImage
    |> where([image], image.message_id == ^from_message_id)
    |> Repo.get_repo().update_all([set: [message_id: to_message_id]], Repo.opts(opts))
  end

  def create_message(attrs, opts \\ []) do
    %Message{} |> Message.changeset(attrs) |> Repo.get_repo().insert(Repo.opts(opts))
  end

  def update_message(message, attrs, opts \\ []) do
    message
    |> Message.changeset(attrs)
    |> Repo.get_repo().update(Repo.opts(opts))
  end

  def mark_message_context_unclear(%Message{} = message, opts \\ []) do
    update_message(
      message,
      %{
        context_review_requested_at: DateTime.utc_now() |> DateTime.truncate(:second),
        context_review_context: message.context
      },
      opts
    )
  end

  def list_context_review_messages(params \\ []) do
    import Ecto.Query

    preloads = params[:preloads] || [:domain, :application_source]

    Message
    |> where([message], not is_nil(message.context_review_requested_at))
    |> order_by([message], desc: message.context_review_requested_at, asc: message.msgid)
    |> preload(^preloads)
    |> Repo.get_repo().all(Repo.opts())
  end

  def clear_context_reviews_for_key(attrs, opts \\ []) do
    import Ecto.Query

    msgid = attrs[:msgid] || attrs["msgid"]
    context = attrs[:context] || attrs["context"] || "default"
    domain_id = attrs[:domain_id] || attrs["domain_id"]
    application_source_id = attrs[:application_source_id] || attrs["application_source_id"]

    Message
    |> where(
      [message],
      message.msgid == ^msgid and message.context != ^context and
        not is_nil(message.context_review_requested_at)
    )
    |> domain_query(domain_id)
    |> application_source_query(application_source_id)
    |> Repo.get_repo().update_all(
      [set: [context_review_requested_at: nil, context_review_context: nil]],
      Repo.opts(opts)
    )
  end

  defp domain_query(query, nil) do
    import Ecto.Query

    where(query, [message], is_nil(message.domain_id))
  end

  defp domain_query(query, domain_id) do
    import Ecto.Query

    where(query, [message], message.domain_id == ^domain_id)
  end

  @doc """
  Deletes a stale message and ALL its translations across ALL locales.

  This function removes the message completely from the system, including
  all singular and plural translations in every locale.

  ## Arguments

    * `message_id` - Integer ID of the message

  ## Returns

    * `{:ok, stats}` - Map containing deletion statistics:
      * `:translations_deleted` - Number of translations deleted across all locales
      * `:message_deleted` - Boolean indicating if message was deleted
    * `{:error, reason}` - If deletion fails

  ## Examples

      iex> ExLingo.Translations.Messages.delete_message(123)
      {:ok, %{translations_deleted: 5, message_deleted: true}}

  """
  def delete_message(message_id) do
    keys = image_keys_for([message_id])

    result =
      Repo.get_repo()
      |> then(& &1.transaction(fn -> delete_message_counts(message_id) end))
      |> invalidate_message_cache_on_success()

    cleanup_s3_images_on_success(result, keys)
  end

  def delete_messages(message_ids) when is_list(message_ids) do
    keys = image_keys_for(message_ids)

    Repo.get_repo()
    |> then(fn repo ->
      repo.transaction(fn ->
        Enum.reduce(message_ids, %{messages_deleted: 0, translations_deleted: 0}, fn message_id,
                                                                                     acc ->
          stats = delete_message_counts(message_id)

          %{
            messages_deleted: acc.messages_deleted + if(stats.message_deleted, do: 1, else: 0),
            translations_deleted: acc.translations_deleted + stats.translations_deleted
          }
        end)
      end)
    end)
    |> invalidate_message_cache_on_success()
    |> cleanup_s3_images_on_success(keys)
  end

  # Removes orphaned S3 objects after the message rows (and their image rows via
  # FK cascade) are gone. Best-effort: failures are logged, never raised, so a
  # storage hiccup can't undo a successful delete.
  defp cleanup_s3_images_on_success({:ok, _result} = result, keys) do
    if S3.configured?() do
      Enum.each(keys, fn key ->
        case S3.delete(key) do
          {:ok, _} -> :ok
          error -> Logger.warning("Failed to delete S3 object #{key}: #{inspect(error)}")
        end
      end)
    end

    result
  end

  defp cleanup_s3_images_on_success(result, _keys), do: result

  defp image_keys_for(message_ids) do
    import Ecto.Query

    MessageImage
    |> where([image], image.message_id in ^message_ids)
    |> select([image], image.s3_key)
    |> Repo.get_repo().all(Repo.opts())
  end

  defp delete_message_counts(message_id) do
    import Ecto.Query

    {singular_count, _} =
      from(st in SingularTranslation, where: st.message_id == ^message_id)
      |> Repo.get_repo().delete_all(Repo.opts())

    {plural_count, _} =
      from(pt in PluralTranslation, where: pt.message_id == ^message_id)
      |> Repo.get_repo().delete_all(Repo.opts())

    {message_count, _} =
      from(m in Message, where: m.id == ^message_id)
      |> Repo.get_repo().delete_all(Repo.opts())

    %{
      translations_deleted: singular_count + plural_count,
      message_deleted: message_count == 1
    }
  end

  defp invalidate_message_cache_on_success({:ok, _stats} = result) do
    ExLingo.Cache.delete_all()
    result
  end

  defp invalidate_message_cache_on_success(result), do: result

  defp application_source_query(query, nil) do
    import Ecto.Query

    where(query, [message], is_nil(message.application_source_id))
  end

  defp application_source_query(query, application_source_id) do
    import Ecto.Query

    where(query, [message], message.application_source_id == ^application_source_id)
  end

  @doc """
  Merges two messages by moving all translations from one message to another.

  This operation:
  1. Deletes all existing translations from the target message
  2. Moves all translations from the source message to the target message
  3. Deletes the source message

  This is useful when a stale message needs to be merged with its replacement
  (e.g., when msgid changes due to typo fixes or wording changes).

  ## Arguments

    * `from_message_id` - ID of the source message (will be deleted)
    * `to_message_id` - ID of the target message (will receive translations)

  ## Returns

    * `{:ok, target_message}` - Target message with merged translations
    * `{:error, :not_found}` - One or both messages not found
    * `{:error, reason}` - Merge failed

  ## Examples

      iex> merge_messages(123, 456)
      {:ok, %Message{id: 456, ...}}

  """
  def merge_messages(from_message_id, to_message_id) do
    import Ecto.Query

    with {:ok, from_message} <- get_message(filter: [id: from_message_id]),
         {:ok, to_message} <- get_message(filter: [id: to_message_id]) do
      # Perform merge in transaction
      Repo.get_repo().transaction(fn ->
        # Delete all translations from target message
        from(st in SingularTranslation,
          where: st.message_id == ^to_message.id
        )
        |> Repo.get_repo().delete_all(Repo.opts())

        from(pt in PluralTranslation,
          where: pt.message_id == ^to_message.id
        )
        |> Repo.get_repo().delete_all(Repo.opts())

        # Move all singular translations from source to target
        from(st in SingularTranslation,
          where: st.message_id == ^from_message.id
        )
        |> Repo.get_repo().update_all([set: [message_id: to_message.id]], Repo.opts())

        # Move all plural translations from source to target
        from(pt in PluralTranslation,
          where: pt.message_id == ^from_message.id
        )
        |> Repo.get_repo().update_all([set: [message_id: to_message.id]], Repo.opts())

        # Move context images to the target before deleting the source, so the
        # FK cascade does not remove them.
        move_images(from_message.id, to_message.id)

        # Delete the source message
        Repo.get_repo().delete(from_message, Repo.opts())

        # Invalidate cache
        ExLingo.Cache.delete_all()

        # Return the target message
        to_message
      end)
    end
  end
end
