defmodule ExLingo.AI.Translations.Provider do
  @moduledoc """
  Behaviour for AI translation suggestion provider plugins.
  """

  alias ExLingo.AI.Translations.SuggestionRequest

  @callback provider_name() :: String.t()
  @callback available_models() :: [String.t()]
  @callback default_model() :: String.t()
  @callback suggest_translation(SuggestionRequest.t()) :: {:ok, String.t()} | {:error, term()}
end
