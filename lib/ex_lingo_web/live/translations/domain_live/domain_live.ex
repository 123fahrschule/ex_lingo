defmodule ExLingoWeb.Translations.DomainLive do
  use ExLingoWeb, :live_view

  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]
  import ExLingoWeb.Translations.Components.ColorField, only: [color_field: 1]

  alias ExLingo.Translations
  alias ExLingo.Translations.Domain

  def mount(%{"id" => id}, _session, socket) do
    socket =
      case get_domain(id) do
        {:ok, %Domain{} = domain} ->
          socket
          |> assign(:domain, domain)
          |> assign_form(domain)

        {:error, _, _reason} ->
          redirect(socket, to: dashboard_path(socket, "/domains"))
      end

    {:ok, socket}
  end

  def handle_event("validate", %{"domain" => attrs}, socket) do
    form =
      socket.assigns.domain
      |> Translations.change_domain(attrs)
      |> Map.put(:action, :update)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"domain" => attrs}, socket) do
    socket =
      case Translations.update_domain(socket.assigns.domain, attrs) do
        {:ok, _domain} ->
          push_navigate(socket, to: dashboard_path(socket, "/domains"))

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  defp get_domain(id) do
    case parse_id_filter(id) do
      {:ok, id} -> Translations.get_domain(filter: [id: id])
      _ -> {:error, :id, :invalid}
    end
  end

  defp assign_form(socket, %Domain{} = domain) do
    assign(socket, :form, to_form(Translations.change_domain(domain)))
  end
end
