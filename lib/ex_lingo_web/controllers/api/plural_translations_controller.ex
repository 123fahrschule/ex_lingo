defmodule ExLingoWeb.Api.PluralTranslationsController do
  @moduledoc false
  use ExLingoWeb, :controller

  plug :put_layout, false

  alias ExLingo.Translations.PluralTranslations.Finders.ListPluralTranslations
  alias ExLingoWeb.Api.ControllerHelpers

  def index(conn, params) do
    ControllerHelpers.with_page(conn, params, fn page ->
      json(conn, ListPluralTranslations.find(page: page))
    end)
  end

  def update(conn, %{"entries" => entries}) do
    ControllerHelpers.populate(conn, "plural_translations", entries)
  end

  def update(conn, _params), do: ControllerHelpers.missing_entries(conn)
end
