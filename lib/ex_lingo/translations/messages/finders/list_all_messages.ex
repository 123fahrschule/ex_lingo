defmodule ExLingo.Translations.Messages.Finders.ListAllMessages do
  @moduledoc """
  Query module aka Finder responsible for listing all gettext messages
  """

  use ExLingo.Query,
    module: ExLingo.Translations.Message,
    binding: :message

  @available_filters ~w(domain_id context_id application_source_id)

  def find(params \\ []) do
    repo = ExLingo.Repo.get_repo()
    filters = params[:filter] || %{}
    query_filters = Map.take(filters, @available_filters)

    base()
    |> filter_query(query_filters)
    |> preload_resources(params[:preloads] || [])
    |> repo.all()
  end
end
