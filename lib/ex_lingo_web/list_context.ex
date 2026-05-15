defmodule ExLingoWeb.ListContext do
  @moduledoc false

  @storage_version "v1"

  def storage_key(socket, list_id) when is_binary(list_id) do
    config = ExLingo.config()
    app_name = config.otp_name || config.name || :ex_lingo
    prefix = socket.router.__ex_lingo_dashboard_prefix__()

    [
      "ex_lingo",
      "list-context",
      @storage_version,
      safe_part(app_name),
      safe_part(prefix),
      safe_part(list_id)
    ]
    |> Enum.join(":")
  end

  def payload(params, available_params) when is_map(params) and is_list(available_params) do
    params
    |> Map.take(available_params)
    |> compact_map()
  end

  def next_sort_direction(%{"field" => field, "direction" => "asc"}, field), do: "desc"
  def next_sort_direction(_sort, _field), do: "asc"

  defp compact_map(map) do
    map
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      value = compact_value(value)

      if empty?(value) do
        acc
      else
        Map.put(acc, key, value)
      end
    end)
  end

  defp compact_value(value) when is_map(value), do: compact_map(value)
  defp compact_value(value) when is_list(value), do: Enum.reject(value, &empty?/1)
  defp compact_value(value), do: value

  defp empty?(value), do: value in [nil, "", %{}, []]

  defp safe_part(value) do
    value
    |> to_string()
    |> Base.url_encode64(padding: false)
  end
end
