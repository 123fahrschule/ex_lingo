defmodule ExLingo.Translations.ApplicationSources.Finders.ListApplicationSources do
  @moduledoc """
  Query module aka Finder responsible for listing application sources
  """

  use ExLingo.Query,
    module: ExLingo.Translations.ApplicationSource,
    binding: :domain

  def find(params \\ []) do
    base()
    |> filter_query(params[:filter])
    |> preload_resources(params[:preloads] || [])
    |> paginate(params[:page], params[:per_page])
  end
end
