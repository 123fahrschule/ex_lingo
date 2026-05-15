defmodule ExLingo.Translations.ApplicationSources.Finders.ListApplicationSources do
  @moduledoc """
  Query module aka Finder responsible for listing application sources
  """

  use ExLingo.Query,
    module: ExLingo.Translations.ApplicationSource,
    binding: :application_source

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

    order_by(query, [application_source: application_source], [
      {^sort_direction, field(application_source, ^sort_field)},
      asc: application_source.id
    ])
  end

  defp sort_query(query, _sort) do
    order_by(query, [application_source: application_source],
      asc: application_source.name,
      asc: application_source.id
    )
  end
end
