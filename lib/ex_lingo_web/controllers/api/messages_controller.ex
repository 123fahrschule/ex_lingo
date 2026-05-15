defmodule ExLingoWeb.Api.MessagesController do
  @moduledoc false
  use ExLingoWeb, :controller

  plug :put_layout, false

  alias ExLingo.Translations.Messages.Finders.ListMessages
  alias ExLingoWeb.Api.ControllerHelpers

  def index(conn, params) do
    ControllerHelpers.with_page(conn, params, fn page ->
      json(conn, ListMessages.find(page: page))
    end)
  end

  def update(conn, %{"entries" => entries}) do
    ControllerHelpers.populate(conn, "messages", entries)
  end

  def update(conn, _params), do: ControllerHelpers.missing_entries(conn)
end
