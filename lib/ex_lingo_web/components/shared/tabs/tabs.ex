defmodule ExLingoWeb.Components.Shared.Tabs do
  @moduledoc """
  Tabs component
  """

  use ExLingoWeb, :live_component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("tab_clicked", %{"index" => index}, socket) do
    uri = URI.parse(socket.assigns.current_url || "")

    query =
      uri.query
      |> decode_query()
      |> Map.put("tab", to_string(index))
      |> URI.encode_query()

    {:noreply, push_patch(socket, to: URI.to_string(%{uri | query: query}))}
  end

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)
end
