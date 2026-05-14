defmodule ExLingo.AI.Providers.OpenAI do
  @moduledoc """
  OpenAI provider plugin for AI translation suggestions.
  """

  @behaviour ExLingo.AI.Translations.Provider

  use GenServer

  alias ExLingo.AI.Providers.OpenAI.Client
  alias ExLingo.AI.Translations.SuggestionRequest

  @default_endpoint "https://api.openai.com/v1/responses"
  @default_models ["gpt-5.4-nano", "gpt-5.4-mini", "gpt-4o-mini"]
  @default_api_key {:system, "OPENAI_API_KEY"}
  @default_timeout 30_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl GenServer
  def init(opts), do: {:ok, opts}

  def validate(opts), do: validate_config(opts)

  @impl ExLingo.AI.Translations.Provider
  def provider_name, do: "OpenAI"

  @impl ExLingo.AI.Translations.Provider
  def available_models, do: config() |> Keyword.get(:allowed_models, @default_models)

  @impl ExLingo.AI.Translations.Provider
  def default_model do
    opts = config()

    Keyword.get(
      opts,
      :default_model,
      List.first(Keyword.get(opts, :allowed_models, @default_models))
    )
  end

  @impl ExLingo.AI.Translations.Provider
  def suggest_translation(%SuggestionRequest{} = request) do
    opts = config()
    model = request.model || default_model()

    with :ok <- validate_model(model, available_models()),
         {:ok, api_key} <- resolve_api_key(Keyword.get(opts, :api_key, @default_api_key)),
         payload <- build_payload(%{request | model: model}),
         {:ok, response} <-
           client(opts).request(endpoint(opts), api_key, payload, request_opts(opts)),
         {:ok, suggestion} <- parse_response(response) do
      {:ok, suggestion}
    end
  end

  def validate_config(opts) do
    cond do
      not Keyword.keyword?(opts) ->
        {:error, "expected OpenAI provider options to be a keyword list"}

      not valid_models?(Keyword.get(opts, :allowed_models, @default_models)) ->
        {:error, "expected :allowed_models to be a non-empty list of strings"}

      default_model = opts[:default_model] ->
        validate_model(default_model, Keyword.get(opts, :allowed_models, @default_models))

      true ->
        :ok
    end
  end

  def validate_model(model, allowed_models) when is_binary(model) and is_list(allowed_models) do
    if model in allowed_models, do: :ok, else: {:error, {:invalid_model, model}}
  end

  def validate_model(model, _allowed_models), do: {:error, {:invalid_model, model}}

  def build_payload(%SuggestionRequest{} = request) do
    %{
      model: request.model || default_model(),
      input: [
        %{role: "system", content: system_prompt()},
        %{role: "user", content: user_prompt(request)}
      ],
      max_output_tokens: 600,
      temperature: 0.2
    }
  end

  def parse_response(%{"output_text" => text}), do: normalize_suggestion(text)

  def parse_response(%{"output" => output}) when is_list(output) do
    output
    |> Enum.flat_map(&Map.get(&1, "content", []))
    |> Enum.find_value(fn
      %{"type" => "output_text", "text" => text} -> text
      %{"text" => text} -> text
      _ -> nil
    end)
    |> normalize_suggestion()
  end

  def parse_response(%{"choices" => [%{"message" => %{"content" => text}} | _]}) do
    normalize_suggestion(text)
  end

  def parse_response(_response), do: {:error, :missing_suggestion}

  def resolve_api_key({:system, env_name}) do
    env_name
    |> System.get_env()
    |> normalize_api_key()
  end

  def resolve_api_key(api_key) when is_binary(api_key), do: normalize_api_key(api_key)
  def resolve_api_key(_api_key), do: {:error, {:missing_api_key, provider_name()}}

  defp normalize_api_key(nil), do: {:error, {:missing_api_key, provider_name()}}

  defp normalize_api_key(api_key) do
    api_key = String.trim(api_key)
    if api_key == "", do: {:error, {:missing_api_key, provider_name()}}, else: {:ok, api_key}
  end

  defp system_prompt do
    """
    You are a translation assistant for software product text in the driving school domain.
    Return only the final translation text.
    Do not include Markdown, labels, quotes, notes, confidence, rationale, or alternatives.
    Follow glossary terminology when relevant.
    """
  end

  defp user_prompt(%SuggestionRequest{} = request) do
    [
      "Source locale: #{request.source_locale}",
      "Target locale: #{request.target_locale}#{target_locale_name(request)}",
      "Message type: #{request.message_type}",
      plural_context(request),
      "Source text:",
      request.source_text,
      current_translation_context(request),
      glossary_context(request)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp target_locale_name(%SuggestionRequest{target_locale_name: nil}), do: ""
  defp target_locale_name(%SuggestionRequest{target_locale_name: name}), do: " (#{name})"

  defp plural_context(%SuggestionRequest{message_type: :plural} = request) do
    "Plural form index: #{request.plural_form_index}\nQuantity examples: #{request.plural_examples}"
  end

  defp plural_context(_request), do: nil

  defp current_translation_context(%SuggestionRequest{current_translation: current_translation}) do
    translated_text = Map.get(current_translation, :translated_text)

    if is_binary(translated_text) and String.trim(translated_text) != "" do
      "Current translation to improve or replace:\n#{translated_text}"
    end
  end

  defp glossary_context(%SuggestionRequest{glossary_entries: []}) do
    "Glossary: no relevant glossary entries."
  end

  defp glossary_context(%SuggestionRequest{glossary_entries: glossary_entries}) do
    entries =
      Enum.map_join(glossary_entries, "\n", fn entry ->
        guidance =
          if is_binary(entry.usage_guidance) and String.trim(entry.usage_guidance) != "" do
            " (#{String.trim(entry.usage_guidance)})"
          else
            ""
          end

        "- #{entry.source_term} => #{entry.target_term}#{guidance}"
      end)

    "Glossary entries to honor when applicable:\n#{entries}"
  end

  defp normalize_suggestion(nil), do: {:error, :empty_suggestion}

  defp normalize_suggestion(text) when is_binary(text) do
    text = String.trim(text)
    if text == "", do: {:error, :empty_suggestion}, else: {:ok, text}
  end

  defp normalize_suggestion(_text), do: {:error, :empty_suggestion}

  defp config do
    ExLingo.config().plugins
    |> Enum.find(&(elem(&1, 0) == __MODULE__))
    |> case do
      nil -> []
      {_module, opts} -> opts
    end
  end

  defp endpoint(opts), do: Keyword.get(opts, :endpoint, @default_endpoint)
  defp client(opts), do: Keyword.get(opts, :client, Client)

  defp request_opts(opts) do
    opts
    |> Keyword.take([:timeout])
    |> Keyword.put_new(:timeout, @default_timeout)
  end

  defp valid_models?(models),
    do: is_list(models) and models != [] and Enum.all?(models, &is_binary/1)
end
