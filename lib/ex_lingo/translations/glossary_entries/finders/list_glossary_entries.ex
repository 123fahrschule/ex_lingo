defmodule ExLingo.Translations.GlossaryEntries.Finders.ListGlossaryEntries do
  @moduledoc """
  Query module responsible for listing glossary entries.
  """

  use ExLingo.Query,
    module: ExLingo.Translations.GlossaryEntry,
    binding: :glossary_entry

  def find(params \\ []) do
    params
    |> query()
    |> paginate(params[:page], params[:per_page])
  end

  def query(params \\ []) do
    base()
    |> filter_query(params[:filter])
    |> preload_resources(params[:preloads] || [])
    |> order_query(asc: :source_locale, asc: :target_locale, asc: :source_term)
  end
end
