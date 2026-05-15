defmodule ExLingo.Translations.Messages.Finders.GetMessage do
  @moduledoc """
  Query module aka Finder responsible for finding gettext message
  """

  use ExLingo.Query,
    module: ExLingo.Translations.Message,
    binding: :message

  alias ExLingo.Cache
  alias ExLingo.Repo
  alias ExLingo.Translations.Message

  def find(params \\ []) do
    cache_key = Cache.generate_cache_key("message", params)

    with {:error, _, :not_cached} <- find_in_cache(cache_key),
         {:ok, %Message{} = message} <- find_in_database(params) do
      Cache.put(cache_key, message)

      {:ok, message}
    else
      {:ok, %Message{} = message} -> {:ok, message}
      {:error, _, :not_found} -> {:error, :message, :not_found}
    end
  end

  defp find_in_cache(cache_key) do
    case Cache.get(cache_key) do
      {:ok, %Message{} = cached_message} ->
        {:ok, cached_message}

      _ ->
        {:error, :message, :not_cached}
    end
  end

  defp find_in_database(params, opts \\ []) do
    base()
    |> filter_query(params[:filter])
    |> search_query(params[:search])
    |> preload_resources(params[:preloads] || [])
    |> limit(1)
    |> one(opts)
    |> case do
      %Message{} = message -> {:ok, message}
      _ -> {:error, :message, :not_found}
    end
    |> database_fallback_public_prefix(params, opts, Repo.get_repo().__adapter__())
  end

  defp database_fallback_public_prefix(
         {:error, :message, :not_found} = result,
         params,
         repo_opts,
         Ecto.Adapters.Postgres
       ) do
    if public_prefix?(repo_opts) or not public_prefix_migrated?() do
      result
    else
      opts = Keyword.put(repo_opts, :prefix, "public")
      find_in_database(params, opts)
    end
  end

  defp database_fallback_public_prefix(result, _, _, _), do: result

  defp public_prefix?(repo_opts) do
    config_prefix = Repo.configured_prefix() || :unset
    opts_prefix = Keyword.get(repo_opts, :prefix, :unset)
    config_prefix in [nil, "public"] or opts_prefix in [nil, "public"]
  end

  defp public_prefix_migrated? do
    Postgresql.migrated_version(%{
      repo: Repo.get_repo(),
      prefix: "public"
    }) > 0
  end
end
