defmodule ExLingo.AI.Providers.OpenAI.Client do
  @moduledoc """
  Minimal HTTP client for the OpenAI Responses API.
  """

  def request(endpoint, api_key, payload, opts \\ []) do
    with {:ok, body} <- Jason.encode(payload) do
      endpoint
      |> do_request(api_key, body, opts)
      |> decode_response()
    end
  end

  defp do_request(endpoint, api_key, body, opts) do
    timeout = Keyword.get(opts, :timeout, 30_000)
    finch_name = Keyword.get(opts, :finch_name, ExLingo.Finch)

    headers = [
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"}
    ]

    Finch.build(:post, endpoint, headers, body)
    |> Finch.request(finch_name, receive_timeout: timeout)
  end

  defp decode_response({:ok, %Finch.Response{status: status, body: body}})
       when status in 200..299 do
    Jason.decode(body)
  end

  defp decode_response({:ok, %Finch.Response{status: status, body: body}}) do
    {:error, {:openai_http_error, status, decode_error_body(body)}}
  end

  defp decode_response({:error, reason}), do: {:error, reason}

  defp decode_error_body(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _reason} -> body
    end
  end
end
