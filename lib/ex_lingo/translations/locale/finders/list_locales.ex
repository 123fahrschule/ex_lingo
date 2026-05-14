defmodule ExLingo.Translations.Locale.Finders.ListLocales do
  @moduledoc """
  Query module aka Finder responsible for listing locales
  """

  use ExLingo.Query,
    module: ExLingo.Translations.Locale,
    binding: :locale

  def find(params \\ []) do
    base()
    |> order_by(:id)
    |> filter_query(params[:filter])
    |> preload_resources(params[:preloads] || [])
    |> paginate(params[:page], params[:per_page])
  end
end
