defmodule ExLingoWeb.Api.ApplicationSourcesController do
  @moduledoc false
  use ExLingoWeb, :controller

  plug :put_layout, false

  alias ExLingo.Translations
  alias ExLingoWeb.Api.ControllerHelpers

  def index(conn, params) do
    ControllerHelpers.with_page(conn, params, fn page ->
      json(conn, Translations.list_application_sources(page: page))
    end)
  end

  def update(conn, %{"entries" => entries}) do
    ControllerHelpers.populate(conn, "application_sources", entries)
  end

  def update(conn, _params), do: ControllerHelpers.missing_entries(conn)
end
