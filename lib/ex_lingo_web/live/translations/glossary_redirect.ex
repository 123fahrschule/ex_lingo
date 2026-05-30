defmodule ExLingoWeb.Translations.GlossaryRedirect do
  @moduledoc """
  Builds the query string used when opening the glossary form prefilled from a
  translation editor.
  """

  alias ExLingo.AI.Translations.Plugin

  @doc """
  Returns a URL-encoded query string with `source_locale`, `target_locale`,
  `source_term`, `target_term`, optional `domain_id`/`application_source_id`,
  and `return_to`.

  `payload` is the client event payload: `%{"source_term" => _, "target_term" => _}`.
  Empty source terms fall back to the full `msgid`; target terms stay empty.
  """
  @spec query_params(map, map, map, binary) :: binary
  def query_params(message, locale, payload, return_to)
      when is_map(message) and is_map(locale) and is_map(payload) and is_binary(return_to) do
    msgid = Map.get(message, :msgid) || ""
    target_locale = Map.get(locale, :iso639_code) || ""

    %{
      "source_locale" => Plugin.source_locale(),
      "target_locale" => target_locale,
      "source_term" => fallback(Map.get(payload, "source_term"), msgid),
      "target_term" => fallback(Map.get(payload, "target_term"), ""),
      "return_to" => return_to
    }
    |> maybe_put("domain_id", Map.get(message, :domain_id))
    |> maybe_put("application_source_id", Map.get(message, :application_source_id))
    |> URI.encode_query()
  end

  defp fallback(nil, fallback), do: fallback
  defp fallback("", fallback), do: fallback

  defp fallback(value, fallback) when is_binary(value) do
    case String.trim(value) do
      "" -> fallback
      trimmed -> trimmed
    end
  end

  defp maybe_put(params, _key, nil), do: params

  defp maybe_put(params, key, value) when is_integer(value),
    do: Map.put(params, key, Integer.to_string(value))

  defp maybe_put(params, key, value) when is_binary(value), do: Map.put(params, key, value)
end
