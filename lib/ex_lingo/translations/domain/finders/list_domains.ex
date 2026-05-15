defmodule ExLingo.Translations.Domains.Finders.ListDomains do
  @moduledoc """
  Query module aka Finder responsible for listing gettext domains
  """

  use ExLingo.Query,
    module: ExLingo.Translations.Domain,
    binding: :domain

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

    order_by(query, [domain: domain], [
      {^sort_direction, field(domain, ^sort_field)},
      asc: domain.id
    ])
  end

  defp sort_query(query, _sort) do
    order_by(query, [domain: domain], asc: domain.name, asc: domain.id)
  end
end
