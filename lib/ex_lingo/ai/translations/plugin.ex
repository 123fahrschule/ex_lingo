defmodule ExLingo.AI.Translations.Plugin do
  @moduledoc """
  Generic ExLingo AI translation suggestion UI plugin.
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
    ExLingo.config().plugins
    |> Enum.find(&(elem(&1, 0) == __MODULE__))
    |> case do
      nil -> nil
      {_module, opts} -> opts
    end
  end
end
