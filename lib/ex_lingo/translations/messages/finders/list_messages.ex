defmodule ExLingo.Translations.Messages.Finders.ListMessages do
  @moduledoc """
  Query module aka Finder responsible for listing gettext messages
  """

  use ExLingo.Query,
    module: ExLingo.Translations.Message,
    binding: :message

  alias ExLingo.Translations.PluralTranslations.Finders.ListPluralTranslations
  alias ExLingo.Translations.SingularTranslations.Finders.ListSingularTranslations

  @available_filters ~w(domain_id application_source_id)
  @sortable_fields ~w(msgid message_type)

  def find(params \\ []) do
    filters = params[:filter] || %{}
    query_filters = Map.take(filters, @available_filters)

    base()
    |> filter_query(query_filters)
    |> message_type_query(filters)
    |> not_translated_query(filters)
    |> stale_query(filters)
    |> search_subquery(filters, params[:search])
    |> sort_query(params[:sort])
    |> distinct(true)
    |> preload_resources(params[:preloads] || [])
    |> paginate(params[:page], params[:per_page])
  end

  defp sort_query(query, %{"field" => field, "direction" => direction})
       when field in @sortable_fields and direction in ["asc", "desc"] do
    sort_field = String.to_existing_atom(field)
    sort_direction = String.to_existing_atom(direction)

    query
    |> exclude(:order_by)
    |> order_by([message: message], [
      {^sort_direction, field(message, ^sort_field)},
      asc: message.id
    ])
  end

  defp sort_query(query, _sort) do
    order_by(query, [message: message], asc: message.msgid, asc: message.id)
  end

  defp message_type_query(query, %{"message_type" => type}) when type in ["singular", "plural"] do
    type_atom = String.to_existing_atom(type)
    where(query, [message: m], m.message_type == ^type_atom)
  end

  defp message_type_query(query, _filters), do: query

  defp not_translated_query(query, %{"locale_id" => locale_id, "not_translated" => "true"}) do
    query
    |> with_join(:singular_translations, locale_id: locale_id)
    |> where(
      [singular_translation: st],
      null_or_empty(st.translated_text) and null_or_empty(st.original_text)
    )
    |> with_join(:plural_translations, locale_id: locale_id)
    |> where(
      [plural_translation: pt],
      null_or_empty(pt.translated_text) and null_or_empty(pt.original_text)
    )
  end

  defp not_translated_query(query, _), do: query

  defp stale_query(query, %{"stale" => "true", "stale_message_ids" => stale_ids})
       when is_struct(stale_ids, MapSet) do
    # System-wide stale detection - filter by message IDs that don't exist in ANY locale's PO files
    if MapSet.size(stale_ids) > 0 do
      stale_id_list = MapSet.to_list(stale_ids)
      where(query, [message: m], m.id in ^stale_id_list)
    else
      # No stale messages - return empty result
      where(query, [message: m], false)
    end
  end

  defp stale_query(query, _), do: query

  defp search_subquery(query, _, nil), do: query
  defp search_subquery(query, _, ""), do: query

  defp search_subquery(query, %{"locale_id" => locale_id}, search) do
    search_subquery(query, [locale_id: locale_id], search)
  end

  defp search_subquery(query, filter, _) when is_map(filter), do: query

  defp search_subquery(query, filter, search) do
    sub =
      base()
      |> search_query(search)
      |> with_join(:singular_translations, filter)
      |> with_join(:plural_translations, filter)
      |> ListPluralTranslations.search_query(search)
      |> ListSingularTranslations.search_query(search)
      |> subquery()

    join(query, :inner, [message: m], sq in ^sub, on: sq.id == m.id)
  end

  def join_resource(query, :singular_translations, opts) do
    locale_id = opts[:locale_id]

    join(query, :left, [message: m], st in assoc(m, :singular_translations),
      as: :singular_translation,
      on: st.message_id == m.id and st.locale_id == ^locale_id
    )
  end

  def join_resource(query, :plural_translations, opts) do
    locale_id = opts[:locale_id]

    join(query, :left, [message: m], pt in assoc(m, :plural_translations),
      as: :plural_translation,
      on: pt.message_id == m.id and pt.locale_id == ^locale_id
    )
  end
end
