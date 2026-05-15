defmodule ExLingo.Translations.GlossaryEntries.Finders.ListGlossaryEntries do
  @moduledoc """
  Query module responsible for listing glossary entries.
  """

  use ExLingo.Query,
    module: ExLingo.Translations.GlossaryEntry,
    binding: :glossary_entry

  alias ExLingo.Translations.Message

  @sortable_fields ~w(source_locale target_locale source_term target_term)

  def find(params \\ []) do
    params
    |> query()
    |> paginate(params[:page], params[:per_page])
  end

  def query(params \\ []) do
    base()
    |> filter_query(params[:filter])
    |> preload_resources(params[:preloads] || [])
    |> sort_query(params[:sort])
  end

  defp sort_query(query, %{"field" => "direction", "direction" => direction})
       when direction in ["asc", "desc"] do
    sort_direction = String.to_existing_atom(direction)

    order_by(query, [glossary_entry: glossary_entry], [
      {^sort_direction, glossary_entry.source_locale},
      {^sort_direction, glossary_entry.target_locale},
      asc: glossary_entry.source_term,
      asc: glossary_entry.id
    ])
  end

  defp sort_query(query, %{"field" => field, "direction" => direction})
       when field in @sortable_fields and direction in ["asc", "desc"] do
    sort_field = String.to_existing_atom(field)
    sort_direction = String.to_existing_atom(direction)

    order_by(query, [glossary_entry: glossary_entry], [
      {^sort_direction, field(glossary_entry, ^sort_field)},
      asc: glossary_entry.id
    ])
  end

  defp sort_query(query, _sort) do
    order_by(query, [glossary_entry: glossary_entry],
      asc: glossary_entry.source_locale,
      asc: glossary_entry.target_locale,
      asc: glossary_entry.source_term,
      asc: glossary_entry.id
    )
  end

  def matching_query(params \\ []) do
    source_text = params[:source_text] || ""

    params
    |> query()
    |> where(
      [glossary_entry: glossary_entry],
      fragment("? ILIKE '%' || ? || '%'", ^source_text, glossary_entry.source_term)
    )
    |> scope_query(params[:message])
  end

  defp scope_query(query, nil) do
    where(
      query,
      [glossary_entry: glossary_entry],
      is_nil(glossary_entry.domain_id) and is_nil(glossary_entry.context_id) and
        is_nil(glossary_entry.application_source_id)
    )
  end

  defp scope_query(query, %Message{} = message) do
    query
    |> scope_field_query(:domain_id, message.domain_id)
    |> scope_field_query(:context_id, message.context_id)
    |> scope_field_query(:application_source_id, message.application_source_id)
  end

  defp scope_field_query(query, field_name, nil) do
    where(
      query,
      [glossary_entry: glossary_entry],
      is_nil(field(glossary_entry, ^field_name))
    )
  end

  defp scope_field_query(query, field_name, field_value) do
    where(
      query,
      [glossary_entry: glossary_entry],
      is_nil(field(glossary_entry, ^field_name)) or
        field(glossary_entry, ^field_name) == ^field_value
    )
  end
end
