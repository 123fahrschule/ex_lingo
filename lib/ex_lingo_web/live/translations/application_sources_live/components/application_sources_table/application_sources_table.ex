defmodule ExLingoWeb.Translations.ApplicationSourcesTable do
  @moduledoc """
  Application sources table component
  """

  use ExLingoWeb, :live_component
  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("edit_application_source", %{"id" => id}, socket) do
    case parse_id_filter(id) do
      {:ok, parsed_id} ->
        {:noreply,
         push_navigate(socket, to: dashboard_path(socket, "/application_sources/#{parsed_id}"))}

      _invalid ->
        {:noreply, socket}
    end
  end

  def truncate_name(name) when is_binary(name) do
    if String.length(name) > 30, do: String.slice(name, 0, 30) <> "...", else: name
  end

  def truncate_name(name), do: name

  def present?(value), do: is_binary(value) and String.trim(value) != ""
end
