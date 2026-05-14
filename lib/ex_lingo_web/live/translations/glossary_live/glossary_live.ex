defmodule ExLingoWeb.Translations.GlossaryLive do
  use ExLingoWeb, :live_view

  alias ExLingo.Translations
  alias ExLingoWeb.Components.Shared.Pagination
  alias ExLingoWeb.Translations.GlossaryEntriesTable

  @filter_keys ~w(source_locale target_locale)

  def mount(params, _session, socket) do
    filters = params |> Map.take(@filter_keys) |> normalize_filters()

    socket =
      socket
      |> assign(:filters, filters)
      |> load_glossary_entries(params["page"] || 1)

    {:ok, socket}
  end

  def handle_event("filter", filters, socket) do
    filters = filters |> Map.take(@filter_keys) |> normalize_filters()

    socket =
      socket
      |> assign(:filters, filters)
      |> load_glossary_entries(1)

    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    socket =
      socket
      |> assign(:filters, %{})
      |> load_glossary_entries(1)

    {:noreply, socket}
  end

  def handle_event("page_changed", %{"index" => page_number}, socket) do
    {:noreply, load_glossary_entries(socket, page_number)}
  end

  defp load_glossary_entries(socket, page) do
    %{entries: glossary_entries, metadata: glossary_entries_metadata} =
      Translations.list_glossary_entries(
        page: page,
        filter: socket.assigns.filters,
        preloads: [:domain, :context, :application_source]
      )

    socket
    |> assign(:glossary_entries, glossary_entries)
    |> assign(:glossary_entries_metadata, glossary_entries_metadata)
  end

  defp normalize_filters(filters) do
    filters
    |> Enum.map(fn {key, value} -> {key, normalize_locale(value)} end)
    |> Enum.reject(fn {_key, value} -> value == "" end)
    |> Enum.into(%{})
  end

  defp normalize_locale(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end
end
