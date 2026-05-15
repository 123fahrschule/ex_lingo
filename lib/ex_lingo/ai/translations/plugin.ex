defmodule ExLingo.AI.Translations.Plugin do
  @moduledoc """
  Generic ExLingo AI translation suggestion UI plugin.

  The process is intentionally registered by ExLingo's plugin supervisor. Today
  most reads still come from ExLingo's config, but keeping a named process gives
  this plugin a stable lifecycle hook for provider state, async suggestion work,
  or runtime configuration refreshes without changing the plugin contract later.
  """

  use GenServer

  @default_source_locale "en"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl GenServer
  def init(opts), do: {:ok, opts}

  def validate(opts) do
    cond do
      not Keyword.keyword?(opts) ->
        {:error, "expected AI translation plugin options to be a keyword list"}

      source_locale = opts[:source_locale] ->
        validate_source_locale(source_locale)

      true ->
        :ok
    end
  end

  def source_locale do
    case plugin_config() do
      nil -> @default_source_locale
      opts -> Keyword.get(opts, :source_locale, @default_source_locale)
    end
  end

  def automatic_suggestions? do
    case plugin_config() do
      nil -> false
      opts -> Keyword.get(opts, :automatic_suggestions, false)
    end
  end

  defp validate_source_locale(source_locale) when is_binary(source_locale), do: :ok

  defp validate_source_locale(source_locale) do
    {:error, "expected :source_locale to be a string, got: #{inspect(source_locale)}"}
  end

  defp plugin_config do
    module = __MODULE__

    ExLingo.config().plugins
    |> Enum.find_value(fn
      {^module, opts} -> opts
      _plugin -> nil
    end)
  end
end
