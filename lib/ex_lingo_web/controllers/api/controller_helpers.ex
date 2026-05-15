defmodule ExLingoWeb.Api.ControllerHelpers do
  @moduledoc false

  import Phoenix.Controller
  import Plug.Conn
  require Logger

  alias ExLingo.Utils.DatabasePopulator

  def with_page(conn, params, callback) when is_function(callback, 1) do
    case parse_page(params) do
      {:ok, page} ->
        callback.(page)

      :error ->
        conn
        |> put_status(400)
        |> json(%{error: "invalid page parameter"})
        |> halt()
    end
  end

  def populate(conn, resource_name, entries) when is_list(entries) do
    case DatabasePopulator.call(resource_name, entries) do
      {:ok, _count} ->
        json(conn, %{status: "OK"})

      {:error, reason} ->
        Logger.error("failed to populate #{resource_name}: #{inspect(reason)}")

        conn
        |> put_status(422)
        |> json(%{error: inspect(reason)})
    end
  rescue
    exception ->
      Logger.error(Exception.format(:error, exception, __STACKTRACE__))

      conn
      |> put_status(500)
      |> json(%{error: "failed to populate #{resource_name}"})
  end

  def populate(conn, _resource_name, _entries) do
    conn
    |> put_status(400)
    |> json(%{error: "entries must be a list"})
  end

  def missing_entries(conn) do
    conn
    |> put_status(400)
    |> json(%{error: "missing entries"})
  end

  defp parse_page(params) do
    params
    |> Map.get("page", "1")
    |> to_string()
    |> Integer.parse()
    |> case do
      {page, ""} when page > 0 -> {:ok, page}
      _invalid -> :error
    end
  end
end
