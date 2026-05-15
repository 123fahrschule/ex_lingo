defmodule ExLingoWeb.Api.SingularTranslationsController do
  @moduledoc false
  use ExLingoWeb, :controller

  plug :put_layout, false

  alias ExLingo.Translations.SingularTranslations.Finders.ListSingularTranslations
  alias ExLingoWeb.Api.ControllerHelpers

  def index(conn, params) do
    ControllerHelpers.with_page(conn, params, fn page ->
      json(conn, ListSingularTranslations.find(page: page))
    end)
  end

  def update(conn, %{"entries" => entries}) do
    ControllerHelpers.populate(conn, "singular_translations", entries)
  end

  def update(conn, _params), do: ControllerHelpers.missing_entries(conn)
end
