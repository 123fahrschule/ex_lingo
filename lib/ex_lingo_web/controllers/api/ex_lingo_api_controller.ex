defmodule ExLingoWeb.Api.ExLingoApiController do
  use ExLingoWeb, :controller

  plug :put_layout, false

  def index(conn, _params) do
    json(conn, %{status: "OK"})
  end
end
