defmodule ExLingo.PoFiles.Services.ExtractMessage do
  @moduledoc """
  Service responsible for extracting gettext messages from .po files
  """

  alias ExLingo.Repo

  alias ExLingo.Translations
  alias ExLingo.Translations.Domain

  @default_domain "default"
  @default_context "default"

  def call(attrs) do
    repo = Repo.get_repo()

    repo.transaction(fn ->
      with {:ok, domain} <- assign_domain(attrs[:domain_name]),
           message_attrs <- assign_message_scope(attrs, domain),
           {_count, _rows} <- Translations.clear_context_reviews_for_key(message_attrs),
           {:ok, message} <- get_or_create_message(message_attrs) do
        message
      else
        {:error, reason} -> repo.rollback(reason)
        error -> repo.rollback(error)
      end
    end)
  end

  def default_domain, do: @default_domain
  def default_context, do: @default_context

  defp get_or_create_message(attrs) do
    case Translations.get_message(filter: message_filter(attrs)) do
      {:ok, message} ->
        update_existing_message(message, attrs)

      {:error, :message, :not_found} ->
        Translations.create_message(attrs)
    end
  end

  defp assign_message_scope(attrs, domain) do
    attrs
    |> Map.put(:context, normalize_context(attrs[:context_name]))
    |> put_domain_id(domain)
  end

  defp put_domain_id(attrs, %Domain{id: domain_id}), do: Map.put(attrs, :domain_id, domain_id)
  defp put_domain_id(attrs, _domain), do: attrs

  defp message_filter(attrs) do
    [
      msgid: attrs[:msgid],
      context: attrs[:context],
      domain_id: nullable_filter(attrs[:domain_id]),
      application_source_id: nullable_filter(attrs[:application_source_id])
    ]
  end

  defp nullable_filter(nil), do: :is_null
  defp nullable_filter(value), do: value

  defp assign_domain(nil), do: {:ok, nil}

  defp assign_domain(domain_name) do
    case Translations.get_domain(filter: [name: domain_name]) do
      {:ok, domain} ->
        {:ok, domain}

      {:error, :domain, :not_found} ->
        Translations.create_domain(%{
          name: domain_name
        })
    end
  end

  defp normalize_context(nil), do: @default_context

  defp normalize_context(context_name) do
    context_name
    |> to_string()
    |> String.trim()
    |> case do
      "" -> @default_context
      context -> context
    end
  end

  defp update_existing_message(message, attrs) do
    changes =
      message
      |> context_changes(attrs)
      |> source_reference_changes(message, attrs)
      |> msgid_plural_changes(message, attrs)

    if changes == %{} do
      {:ok, message}
    else
      case Translations.update_message(message, changes) do
        {:ok, message} ->
          ExLingo.Cache.delete_all()
          {:ok, message}

        error ->
          error
      end
    end
  end

  defp msgid_plural_changes(changes, message, attrs) do
    incoming = attrs[:msgid_plural]

    if is_binary(incoming) and incoming != "" and message.msgid_plural != incoming do
      Map.put(changes, :msgid_plural, incoming)
    else
      changes
    end
  end

  defp context_changes(message, attrs) do
    if message.context == attrs[:context] do
      %{}
    else
      %{
        context: attrs[:context],
        context_review_requested_at: nil,
        context_review_context: nil
      }
    end
  end

  defp source_reference_changes(changes, message, attrs) do
    incoming_references = Map.get(attrs, :source_references, [])

    with true <- incoming_references != [],
         merged_references <-
           merge_source_references(message.source_references, incoming_references),
         false <- merged_references == (message.source_references || []) do
      Map.put(changes, :source_references, merged_references)
    else
      _no_update_needed -> changes
    end
  end

  defp merge_source_references(existing_references, incoming_references) do
    (List.wrap(existing_references) ++ List.wrap(incoming_references))
    |> Enum.uniq_by(&source_reference_key/1)
  end

  defp source_reference_key(%{"file" => file, "line" => line}), do: {file, line}
  defp source_reference_key(%{file: file, line: line}), do: {file, line}
  defp source_reference_key(reference), do: reference
end
