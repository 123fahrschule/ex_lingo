defmodule ExLingo.Translations.GlossaryEntries.Finders.GetGlossaryEntry do
  @moduledoc """
  Query module responsible for finding a glossary entry.
  """

  use ExLingo.Query,
    module: ExLingo.Translations.GlossaryEntry,
    binding: :glossary_entry

  alias ExLingo.Translations.GlossaryEntry

  def find(params \\ []) do
    base()
    |> filter_query(params[:filter])
    |> preload_resources(params[:preloads] || [])
    |> one()
    |> case do
      %GlossaryEntry{} = glossary_entry -> {:ok, glossary_entry}
      _ -> {:error, :glossary_entry, :not_found}
    end
  end
end
