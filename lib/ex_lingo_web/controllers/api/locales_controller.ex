defmodule ExLingoWeb.Api.LocalesController do
  @moduledoc false
  use ExLingoWeb, :controller

  plug :put_layout, false

  alias ExLingo.Translations.Locale.Finders.ListLocales
  alias ExLingoWeb.Api.ControllerHelpers

  def index(conn, params) do
    ControllerHelpers.with_page(conn, params, fn page ->
      json(conn, ListLocales.find(page: page))
    end)
  end

  def update(conn, %{"entries" => entries}) do
    ControllerHelpers.populate(conn, "locales", entries)
  end

  def update(conn, _params), do: ControllerHelpers.missing_entries(conn)
end
