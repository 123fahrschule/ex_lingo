defmodule ExLingo.Translations.PluralTranslations.Finders.ListPluralTranslations do
  @moduledoc """
  Query module aka Finder responsible for listing plural translations
  """

  use ExLingo.Query,
    module: ExLingo.Translations.PluralTranslation,
    binding: :plural_translation

  def find(params \\ []) do
    filters = params[:filter] || %{}
    search = params[:search] || ""

    query =
      base()
      |> filter_query(filters)
      |> search_query(search)
      |> preload_resources(params[:preloads] || [])

    if params[:skip_pagination] do
      all(query)
    else
      paginate(query, params[:page], params[:per_page])
    end
  end
end
