defmodule ExLingo.Translations.Locale.Utils.LocaleCodeMapper do
  @moduledoc """
  Utility for mapping locales data from iso code
  """

  @dictionary_path Path.expand("../../../../../priv/iso639.json", __DIR__)
  @dictionary @dictionary_path |> File.read!() |> Jason.decode!()

  def get_native_name(code) do
    case Map.fetch(@dictionary, code) do
      {:ok, info} -> info["nativeName"]
      _ -> code
    end
  end

  def get_name(code) do
    case Map.fetch(@dictionary, code) do
      {:ok, info} -> info["name"]
      _ -> code
    end
  end

  def get_family(code) do
    case Map.fetch(@dictionary, code) do
      {:ok, info} -> info["family"]
      _ -> "unknown"
    end
  end

  def get_wiki_url(code) do
    case Map.fetch(@dictionary, code) do
      {:ok, info} -> info["wikiUrl"]
      _ -> "unknown"
    end
  end

  def get_colors(code) do
    case Map.fetch(@dictionary, code) do
      {:ok, info} -> info["colors"]
      _ -> ["#000000"]
    end
  end
end
