defmodule ExLingoWeb.Translations.DomainsTable do
  @moduledoc """
  Gettext domains table component
  """

  use ExLingoWeb, :live_component

  def update(socket, assigns) do
    {:ok, assign(assigns, socket)}
  end

  def handle_event("edit_domain", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: dashboard_path(socket, "/domains/#{id}"))}
  end
end
