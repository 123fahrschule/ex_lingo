defmodule ExLingoWeb.Api.ExLingoApiController do
  use ExLingoWeb, :controller

  plug :put_layout, false

  def index(conn, _params) do
    conn
    |> put_status(200)
    |> json(%{status: "OK"})
  end
end
