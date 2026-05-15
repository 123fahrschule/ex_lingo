defmodule ExLingo.Cache do
  @moduledoc """
  ExLingo Cache for minimalizing calls to DB
  """

  use Nebulex.Cache,
    otp_app: :ex_lingo,
    adapter: Nebulex.Adapters.Partitioned,
    adapter_opts: [primary_storage_adapter: Nebulex.Adapters.Local]

  def generate_cache_key(prefix, params) do
    Enum.reduce(params, prefix, fn {key, value}, acc ->
      case value do
        val when is_binary(val) ->
          acc <> "_" <> to_string(key) <> "_" <> URI.encode(val)

        val when is_list(val) ->
          # this old way is just broken for preloads lists
          # encoded_list = (Enum.into(val, %{}) |> URI.encode_query())
          # the new way is robust and reversible
          encoded_list =
            val
            |> :erlang.term_to_binary()
            |> URI.encode()
            |> then(&%{encoded_params: &1})
            |> URI.encode_query()

          acc <> "_" <> to_string(key) <> "_" <> encoded_list

        _val ->
          acc
      end
    end)
  end
end
