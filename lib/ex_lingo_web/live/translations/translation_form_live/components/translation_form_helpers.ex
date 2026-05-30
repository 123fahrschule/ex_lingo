defmodule ExLingoWeb.Translations.TranslationFormHelpers do
  @moduledoc """
  Shared helpers for the inline singular/plural translation editors:
  AI request options, AI error messages, and list-return query building.
  """

  import ExLingoWeb.I18n

  alias ExLingo.AI.Translations.{Plugin, Suggestions}

  @doc """
  Options for an AI suggestion request using the default provider/model.
  """
  def ai_request_opts do
    provider = List.first(Suggestions.provider_options())

    [
      provider_id: provider && provider.id,
      model: provider && provider.default_model,
      source_locale: Plugin.source_locale()
    ]
  end

  @doc """
  Human-readable error message for an AI suggestion failure reason.
  """
  def error_message(:provider_not_configured),
    do: t("No AI translation provider is configured.")

  def error_message({:invalid_provider, provider}),
    do: t("Invalid AI provider: %{provider}.", provider: inspect(provider))

  def error_message({:missing_api_key, _provider}),
    do: t("The AI provider API key is missing.")

  def error_message({:invalid_model, model}),
    do: t("Model %{model} is not allowed for this provider.", model: model)

  def error_message(reason),
    do: t("Could not generate a suggestion: %{reason}", reason: inspect(reason))

  @doc """
  Builds the `?...` query string used to return to the filtered list.
  """
  def get_query(%{filters: filters}) when not is_nil(filters) do
    query = UriQuery.params(filters)
    "?" <> URI.encode_query(query)
  end

  def get_query(_assigns), do: ""
end
