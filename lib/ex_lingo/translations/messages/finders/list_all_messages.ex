defmodule ExLingo.Translations.Messages.Finders.ListAllMessages do
  @moduledoc """
  Query module aka Finder responsible for listing all gettext messages
  """

  use ExLingo.Query,
    module: ExLingo.Translations.Message,
    binding: :message

  @available_filters ~w(domain_id)a

  def find(params \\ []) do
    filters = params[:filter] || %{}
    query_filters = Map.take(filters, @available_filters)

    base()
    |> filter_query(query_filters)
    |> preload_resources(params[:preloads] || [])
    |> ExLingo.Repo.get_repo().all(ExLingo.Repo.opts())
  end
end
