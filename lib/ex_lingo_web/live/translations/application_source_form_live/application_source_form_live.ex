defmodule ExLingoWeb.Translations.ApplicationSourceFormLive do
  use ExLingoWeb, :live_view

  alias ExLingo.Translations
  alias ExLingo.Translations.ApplicationSource
  import ExLingoWeb.Translations.Components.ColorField, only: [color_field: 1]

  def mount(%{"id" => application_source_id}, _session, socket) do
    socket =
      case get_application_source(application_source_id) do
        nil ->
          redirect(socket, to: dashboard_path(socket, "/application_sources"))

        application_source ->
          form = Translations.change_application_source(application_source)

          socket
          |> assign(:form, to_form(form))
          |> assign(:application_source, application_source)
          |> assign(:editing, true)
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    form = Translations.change_application_source(%ApplicationSource{})

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:editing, false)

    {:ok, socket}
  end

  def handle_event("validate", %{"application_source" => attrs}, socket) do
    {action, application_source} =
      if socket.assigns.editing do
        {:update, socket.assigns.application_source}
      else
        {:insert, %ApplicationSource{}}
      end

    form =
      application_source
      |> Translations.change_application_source(attrs)
      |> Map.put(:action, action)

    socket = assign(socket, form: to_form(form))

    {:noreply, socket}
  end

  def handle_event(
        "submit",
        %{"application_source" => attrs},
        %{assigns: %{application_source: application_source}} = socket
      ) do
    socket =
      case Translations.update_application_source(application_source, attrs) do
        {:ok, _application_source} ->
          push_navigate(socket, to: dashboard_path(socket, "/application_sources"))

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("submit", %{"application_source" => attrs}, socket) do
    socket =
      case Translations.create_application_source(attrs) do
        {:ok, _application_source} ->
          push_navigate(socket, to: dashboard_path(socket, "/application_sources"))

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  defp get_application_source(id) do
    case Translations.get_application_source(filter: [id: id]) do
      {:ok, application_source} -> application_source
      {:error, _, _reason} -> nil
    end
  end
end
