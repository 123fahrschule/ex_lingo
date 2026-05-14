defmodule ExLingo.Translations.GlossaryEntries do
  @moduledoc """
  Glossary entries ExLingo subcontext.
  """

  alias ExLingo.Repo
  alias ExLingo.Translations.GlossaryEntries.Finders.{GetGlossaryEntry, ListGlossaryEntries}
  alias ExLingo.Translations.GlossaryEntry

  def list_glossary_entries(params \\ []) do
    ListGlossaryEntries.find(params)
  end

  def list_all_glossary_entries(params \\ []) do
    params
    |> ListGlossaryEntries.query()
    |> Repo.get_repo().all(Repo.opts())
  end

  def get_glossary_entry(params) do
    GetGlossaryEntry.find(params)
  end

  def create_glossary_entry(attrs, opts \\ []) do
    %GlossaryEntry{}
    |> GlossaryEntry.changeset(attrs)
    |> Repo.get_repo().insert(Repo.opts(opts))
  end

  def update_glossary_entry(%GlossaryEntry{} = glossary_entry, attrs, opts \\ []) do
    glossary_entry
    |> GlossaryEntry.changeset(attrs)
    |> Repo.get_repo().update(Repo.opts(opts))
  end

  def delete_glossary_entry(%GlossaryEntry{} = glossary_entry, opts \\ []) do
    Repo.get_repo().delete(glossary_entry, Repo.opts(opts))
  end

  def change_glossary_entry(%GlossaryEntry{} = glossary_entry, params \\ %{}) do
    GlossaryEntry.changeset(glossary_entry, params)
  end
end
