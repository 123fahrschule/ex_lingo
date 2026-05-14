defmodule ExLingo.Translations.ApplicationSources.Finders.GetApplicationSource do
  @moduledoc """
  Query module aka Finder responsible for finding application source
  """

  use ExLingo.Query,
    module: ExLingo.Translations.ApplicationSource,
    binding: :domain

  alias ExLingo.Cache
  alias ExLingo.Translations.ApplicationSource

  def find(params \\ []) do
    cache_key = Cache.generate_cache_key("application_source", params)

    with {:error, _, :not_cached} <- find_in_cache(cache_key),
         {:ok, %ApplicationSource{} = application_source} <- find_in_database(params) do
      Cache.put(cache_key, application_source)

      {:ok, application_source}
    else
      {:ok, %ApplicationSource{} = application_source} -> {:ok, application_source}
      {:error, _, :not_found} -> {:error, :application_source, :not_found}
    end
  end

  defp find_in_cache(cache_key) do
    case Cache.get(cache_key) do
      {:ok, %ApplicationSource{} = cached_application_source} ->
        {:ok, cached_application_source}

      _ ->
        {:error, :application_source, :not_cached}
    end
  end

  defp find_in_database(params) do
    base()
    |> filter_query(params[:filter])
    |> preload_resources(params[:preloads] || [])
    |> one()
    |> case do
      %ApplicationSource{} = application_source -> {:ok, application_source}
      _ -> {:error, :application_source, :not_found}
    end
  end
end
