defmodule ExLingoWeb.Api.DomainsController do
  @moduledoc false
  use ExLingoWeb, :controller

  plug :put_layout, false

  alias ExLingo.Translations.Domains.Finders.ListDomains
  alias ExLingoWeb.Api.ControllerHelpers

  def index(conn, params) do
    ControllerHelpers.with_page(conn, params, fn page ->
      json(conn, ListDomains.find(page: page))
    end)
  end

  def update(conn, %{"entries" => entries}) do
    ControllerHelpers.populate(conn, "domains", entries)
  end

  def update(conn, _params), do: ControllerHelpers.missing_entries(conn)
end
