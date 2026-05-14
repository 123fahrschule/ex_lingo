defmodule ExLingo.Translations.Contexts.Finders.ListAllContexts do
  @moduledoc """
  Query module aka Finder responsible for listing all gettext contexts
  """

  use ExLingo.Query,
    module: ExLingo.Translations.Context,
    binding: :context

  def find(params \\ []) do
    base()
    |> filter_query(params[:filter])
    |> preload_resources(params[:preloads] || [])
    |> ExLingo.Repo.get_repo().all(ExLingo.Repo.opts())
  end
end
