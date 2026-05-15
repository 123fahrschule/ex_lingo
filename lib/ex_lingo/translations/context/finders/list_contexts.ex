defmodule ExLingo.Translations.Contexts.Finders.ListContexts do
  @moduledoc """
  Query module aka Finder responsible for listing gettext contexts
  """

  use ExLingo.Query,
    module: ExLingo.Translations.Context,
    binding: :context

  @sortable_fields ~w(name description color)

  def find(params \\ []) do
    base()
    |> filter_query(params[:filter])
    |> sort_query(params[:sort])
    |> preload_resources(params[:preloads] || [])
    |> paginate(params[:page], params[:per_page])
  end

  defp sort_query(query, %{"field" => field, "direction" => direction})
       when field in @sortable_fields and direction in ["asc", "desc"] do
    sort_field = String.to_existing_atom(field)
    sort_direction = String.to_existing_atom(direction)

    order_by(query, [context: context], [
      {^sort_direction, field(context, ^sort_field)},
      asc: context.id
    ])
  end

  defp sort_query(query, _sort) do
    order_by(query, [context: context], asc: context.name, asc: context.id)
  end
end
