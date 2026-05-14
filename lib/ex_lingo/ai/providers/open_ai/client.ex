defmodule ExLingo.AI.Providers.OpenAI.Client do
  @moduledoc """
  Minimal HTTP client for the OpenAI Responses API.
  """

  def request(endpoint, api_key, payload, opts \\ []) do
    with {:ok, body} <- Jason.encode(payload),
         :ok <- ensure_http_started() do
      endpoint
      |> do_request(api_key, body, opts)
      |> decode_response()
    end
  end

  defp ensure_http_started do
    with {:ok, _} <- Application.ensure_all_started(:inets),
         {:ok, _} <- Application.ensure_all_started(:ssl) do
      :ok
    else
      {:error, reason} -> {:error, {:http_not_started, reason}}
    end
  end

  defp do_request(endpoint, api_key, body, opts) do
    timeout = Keyword.get(opts, :timeout, 30_000)

    headers = [
      {~c"authorization", ~c"Bearer #{api_key}"},
      {~c"content-type", ~c"application/json"}
    ]

    :httpc.request(
      :post,
      {String.to_charlist(endpoint), headers, ~c"application/json", String.to_charlist(body)},
      [timeout: timeout],
      body_format: :binary
    )
  end

  defp decode_response({:ok, {{_http_version, status, _reason}, _headers, body}})
       when status in 200..299 do
    Jason.decode(body)
  end

  defp decode_response({:ok, {{_http_version, status, _reason}, _headers, body}}) do
    {:error, {:openai_http_error, status, body}}
  end

  defp decode_response({:error, reason}), do: {:error, reason}
end
