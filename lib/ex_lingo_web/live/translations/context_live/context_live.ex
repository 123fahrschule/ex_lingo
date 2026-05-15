defmodule ExLingoWeb.Translations.ContextLive do
  use ExLingoWeb, :live_view

  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]
  import ExLingoWeb.Translations.Components.ColorField, only: [color_field: 1]

  alias ExLingo.Translations
  alias ExLingo.Translations.Context

  def mount(%{"id" => id}, _session, socket) do
    socket =
      case get_context(id) do
        {:ok, %Context{} = context} ->
          socket
          |> assign(:context, context)
          |> assign_form(context)

        {:error, _, _reason} ->
          redirect(socket, to: dashboard_path(socket, "/contexts"))
      end

    {:ok, socket}
  end

  def handle_event("validate", %{"context" => attrs}, socket) do
    form =
      socket.assigns.context
      |> Translations.change_context(attrs)
      |> Map.put(:action, :update)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"context" => attrs}, socket) do
    socket =
      case Translations.update_context(socket.assigns.context, attrs) do
        {:ok, _context} ->
          push_navigate(socket, to: dashboard_path(socket, "/contexts"))

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  defp get_context(id) do
    case parse_id_filter(id) do
      {:ok, id} -> Translations.get_context(filter: [id: id])
      _ -> {:error, :id, :invalid}
    end
  end

  defp assign_form(socket, %Context{} = context) do
    assign(socket, :form, to_form(Translations.change_context(context)))
  end
end
