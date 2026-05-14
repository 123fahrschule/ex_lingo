defmodule ExLingo.Translations.Domains.Finders.ListAllDomains do
  @moduledoc """
  Query module aka Finder responsible for listing all gettext domains
  """

  use ExLingo.Query,
    module: ExLingo.Translations.Domain,
    binding: :domain

  def find(params \\ []) do
    repo = ExLingo.Repo.get_repo()

    base()
    |> filter_query(params[:filter])
    |> preload_resources(params[:preloads] || [])
    |> repo.all()
  end
end
