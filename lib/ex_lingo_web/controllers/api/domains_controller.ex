defmodule ExLingoWeb.Api.DomainsController do
  @moduledoc false
  use ExLingoWeb, :controller

  plug :put_layout, false

  alias ExLingo.Translations.Domains.Finders.ListDomains
  alias ExLingo.Utils.DatabasePopulator

  def index(conn, params) do
    page = params |> Map.get("page", "1") |> String.to_integer()

    conn
    |> put_status(200)
    |> json(ListDomains.find(page: page))
  end

  def update(conn, %{"entries" => entries}) do
    DatabasePopulator.call("domains", entries)

    conn
    |> put_status(200)
    |> json(%{status: "OK"})
  end
end
