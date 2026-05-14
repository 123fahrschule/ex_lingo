defmodule ExLingo.Translations.Locale.Finders.GetLocale do
  @moduledoc """
  Query module aka Finder responsible for finding locale
  """

  use ExLingo.Query,
    module: ExLingo.Translations.Locale,
    binding: :locale

  alias ExLingo.Cache
  alias ExLingo.Translations.Locale

  def find(params \\ []) do
    cache_key = Cache.generate_cache_key("locale", params)

    with {:error, _, :not_cached} <- find_in_cache(cache_key),
         {:ok, %Locale{} = locale} <- find_in_database(params) do
      Cache.put(cache_key, locale)

      {:ok, locale}
    else
      {:ok, %Locale{} = locale} -> {:ok, locale}
      {:error, _, :not_found} -> {:error, :locale, :not_found}
    end
  end

  defp find_in_cache(cache_key) do
    case Cache.get(cache_key) do
      {:ok, %Locale{} = cached_locale} ->
        {:ok, cached_locale}

      _ ->
        {:error, :locale, :not_cached}
    end
  end

  defp find_in_database(params) do
    base()
    |> filter_query(params[:filter])
    |> preload_resources(params[:preloads] || [])
    |> one()
    |> case do
      %Locale{} = locale -> {:ok, locale}
      _ -> {:error, :locale, :not_found}
    end
  end
end
