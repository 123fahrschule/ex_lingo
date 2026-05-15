defmodule ExLingoWeb.Components.Shared.Toggle do
  @moduledoc """
  Toggle/Checkbox component
  """

  use ExLingoWeb, :live_component

  def update(assigns, socket) do
    checked = checked_value(assigns[:field], assigns[:default_value])
    switch_id = "#{assigns.id}-#{if checked, do: "on", else: "off"}"

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:checked, checked)
     |> assign(:switch_id, switch_id)}
  end

  def handle_event("update", %{"id" => id, "state" => state}, socket) do
    is_on = state in [true, "true", "1", "on"]

    send(self(), {:toggle_updated, id, is_on})

    {:noreply, assign(socket, :is_on, is_on)}
  end

  defp checked_value(%Phoenix.HTML.FormField{value: value}, default_value) do
    case value do
      nil -> truthy?(default_value)
      "" -> truthy?(default_value)
      value -> truthy?(value)
    end
  end

  defp checked_value(_field, default_value), do: truthy?(default_value)

  defp truthy?(value), do: value in [true, "true", "1", "on", 1]
end
