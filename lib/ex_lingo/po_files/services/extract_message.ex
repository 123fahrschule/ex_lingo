defmodule ExLingo.PoFiles.Services.ExtractMessage do
  @moduledoc """
  Service responsible for extracting gettext messages from .po files
  """

  alias ExLingo.Repo

  alias ExLingo.Translations
  alias ExLingo.Translations.{Context, Domain}

  @default_domain "default"
  @default_context "default"

  def call(attrs) do
    repo = Repo.get_repo()

    repo.transaction(fn ->
      with {:ok, domain} <- assign_domain(attrs[:domain_name]),
           {:ok, context} <- assign_context(attrs[:context_name]),
           {:ok, message} <- get_or_create_message(attrs, context, domain) do
        message
      else
        {:error, reason} -> repo.rollback(reason)
        error -> repo.rollback(error)
      end
    end)
  end

  def default_domain, do: @default_domain
  def default_context, do: @default_context

  defp get_or_create_message(attrs, nil, nil) do
    case Translations.get_message(filter: [msgid: attrs[:msgid]]) do
      {:ok, message} -> update_message_source_references(message, attrs)
      {:error, :message, :not_found} -> Translations.create_message(attrs)
    end
  end

  defp get_or_create_message(attrs, %Context{id: context_id}, %Domain{id: domain_id}) do
    case Translations.get_message(
           filter: [msgid: attrs[:msgid], context_id: context_id, domain_id: domain_id]
         ) do
      {:ok, message} ->
        update_message_source_references(message, attrs)

      {:error, :message, :not_found} ->
        attrs
        |> Map.put(:context_id, context_id)
        |> Map.put(:domain_id, domain_id)
        |> Translations.create_message()
    end
  end

  defp get_or_create_message(attrs, %Context{id: context_id}, nil) do
    case Translations.get_message(filter: [msgid: attrs[:msgid], context_id: context_id]) do
      {:ok, message} ->
        update_message_source_references(message, attrs)

      {:error, :message, :not_found} ->
        with {:ok, %Domain{id: domain_id}} <- assign_domain(@default_domain) do
          attrs
          |> Map.put(:context_id, context_id)
          |> Map.put(:domain_id, domain_id)
          |> Translations.create_message()
        end
    end
  end

  defp get_or_create_message(%{msgid: msgid} = attrs, nil, %Domain{id: domain_id}) do
    case Translations.get_message(filter: [msgid: msgid, domain_id: domain_id]) do
      {:ok, message} ->
        update_message_source_references(message, attrs)

      {:error, :message, :not_found} ->
        with {:ok, %Context{id: context_id}} <- assign_context(@default_context) do
          attrs
          |> Map.put(:context_id, context_id)
          |> Map.put(:domain_id, domain_id)
          |> Translations.create_message()
        end
    end
  end

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

  defp assign_context(nil), do: {:ok, nil}

  defp assign_context(context_name) do
    case Translations.get_context(filter: [name: context_name]) do
      {:ok, context} ->
        {:ok, context}

      {:error, :context, :not_found} ->
        Translations.create_context(%{
          name: context_name
        })
    end
  end

  defp update_message_source_references(message, attrs) do
    incoming_references = Map.get(attrs, :source_references, [])

    with true <- incoming_references != [],
         merged_references <-
           merge_source_references(message.source_references, incoming_references),
         false <- merged_references == (message.source_references || []) do
      case Translations.update_message(message, %{source_references: merged_references}) do
        {:ok, message} ->
          ExLingo.Cache.delete_all()
          {:ok, message}

        error ->
          error
      end
    else
      _no_update_needed -> {:ok, message}
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
