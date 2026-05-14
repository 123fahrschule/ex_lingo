defmodule ExLingo.Translations.Contexts.Finders.ListContexts do
  @moduledoc """
  Query module aka Finder responsible for listing gettext contexts
  """

  use ExLingo.Query,
    module: ExLingo.Translations.Context,
    binding: :context

  def find(params \\ []) do
    base()
    |> filter_query(params[:filter])
    |> preload_resources(params[:preloads] || [])
    |> paginate(params[:page], params[:per_page])
  end
end
