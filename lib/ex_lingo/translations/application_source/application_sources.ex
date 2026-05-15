defmodule ExLingo.Translations.ApplicationSources do
  @moduledoc """
  ApplicationSources ExLingo subcontext
  """

  alias ExLingo.Translations.ApplicationSource
  alias ExLingo.Repo
  import Ecto.Query, only: [from: 2]

  alias ExLingo.Translations.ApplicationSources.Finders.{
    GetApplicationSource,
    ListApplicationSources
  }

  def list_application_sources(params \\ []) do
    ListApplicationSources.find(params)
  end

  def get_application_source(params) do
    GetApplicationSource.find(params)
  end

  def create_application_source(attrs, opts \\ []) do
    %ApplicationSource{}
    |> ApplicationSource.changeset(attrs)
    |> Repo.get_repo().insert(Repo.opts(opts))
  end

  def update_application_source(%ApplicationSource{} = application_source, attrs, opts \\ []) do
    application_source
    |> ApplicationSource.changeset(attrs)
    |> Repo.get_repo().update(Repo.opts(opts))
  end

  def change_application_source(%ApplicationSource{} = application_source, params \\ %{}) do
    ApplicationSource.changeset(application_source, params)
  end

  def application_sources_empty? do
    query = from(application_source in ApplicationSource, select: 1, limit: 1)

    not Repo.get_repo().exists?(query, Repo.opts())
  end
end
