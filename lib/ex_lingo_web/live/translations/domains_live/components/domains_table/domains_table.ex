defmodule ExLingoWeb.Translations.DomainsTable do
  @moduledoc """
  Gettext domains table component
  """

  use ExLingoWeb, :live_component
  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("edit_domain", %{"id" => id}, socket) do
    case parse_id_filter(id) do
      {:ok, parsed_id} ->
        {:noreply, push_navigate(socket, to: dashboard_path(socket, "/domains/#{parsed_id}"))}

      _invalid ->
        {:noreply, socket}
    end
  end

  def truncate_name(name) when is_binary(name), do: String.slice(name, 0, 30)
  def truncate_name(name), do: name

  def present?(value), do: is_binary(value) and String.trim(value) != ""
end
