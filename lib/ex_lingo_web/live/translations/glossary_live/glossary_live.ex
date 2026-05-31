defmodule ExLingoWeb.Translations.GlossaryLive do
  use ExLingoWeb, :live_view

  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]

  alias ExLingo.Translations
  alias ExLingo.Translations.GlossaryEntry
  alias ExLingoWeb.Components.Shared.Pagination
  alias ExLingoWeb.ListContext
  alias ExLingoWeb.Translations.GlossaryEntriesTable

  @filter_keys ~w(source_locale target_locale)
  @available_params @filter_keys ++ ~w(page page_size sort)
  @list_context_prefixes @filter_keys ++ ~w(page page_size sort[ clear_list_context)
  @sortable_fields ~w(direction source_term target_term)
  @scope_options_limit 100
  @default_page_size 100

  def mount(params, _session, socket) do
    filters = params |> Map.take(@filter_keys) |> normalize_filters()

    socket =
      socket
      |> assign(:list_context_storage_key, ListContext.storage_key(socket, "glossary"))
      |> assign(:list_context_prefixes, @list_context_prefixes)
      |> assign(:editing_glossary_entry, nil)
      |> assign(:glossary_entry_form, nil)
      |> assign(:glossary_entry_editing?, false)
      |> assign(:filters, filters)
      |> assign(:sort, normalize_sort(params["sort"]))
      |> assign_scope_options()
      |> load_glossary_entries(
        normalize_page(params["page"]),
        normalize_page_size(params["page_size"])
      )

    {:ok, socket}
  end

  def handle_info(:refresh_glossary_entries, socket) do
    {:noreply,
     load_glossary_entries(
       socket,
       current_page(socket, :glossary_entries_metadata),
       current_page_size(socket, :glossary_entries_metadata)
     )}
  end

  def handle_event("filter", filters, socket) do
    filters = filters |> Map.take(@filter_keys) |> normalize_filters()

    socket =
      socket
      |> assign(:filters, filters)
      |> load_glossary_entries(1, current_page_size(socket, :glossary_entries_metadata))

    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    socket =
      socket
      |> assign(:filters, %{})
      |> assign(:sort, %{})
      |> load_glossary_entries(1, current_page_size(socket, :glossary_entries_metadata))

    {:noreply, socket}
  end

  def handle_event("page_changed", params, socket) do
    {page, page_size} = normalize_pagination(params)
    {:noreply, load_glossary_entries(socket, page, page_size)}
  end

  def handle_event("new_glossary_entry", _params, socket) do
    {:noreply, assign_glossary_entry_editor(socket, %GlossaryEntry{}, false)}
  end

  def handle_event("edit_glossary_entry", %{"id" => id}, socket) do
    socket =
      case get_glossary_entry(id) do
        {:ok, %GlossaryEntry{} = glossary_entry} ->
          assign_glossary_entry_editor(socket, glossary_entry, true)

        {:error, _, _reason} ->
          put_flash(socket, :error, t("Could not load glossary entry."))
      end

    {:noreply, socket}
  end

  def handle_event("close_glossary_entry_editor", _params, socket) do
    {:noreply, clear_glossary_entry_editor(socket)}
  end

  def handle_event("validate_glossary_entry", %{"glossary_entry" => attrs}, socket) do
    action = if socket.assigns.glossary_entry_editing?, do: :update, else: :insert

    form =
      socket.assigns.editing_glossary_entry
      |> Translations.change_glossary_entry(normalize_attrs(attrs))
      |> Map.put(:action, action)
      |> to_form()

    {:noreply, assign(socket, :glossary_entry_form, form)}
  end

  def handle_event("submit_glossary_entry", %{"glossary_entry" => attrs}, socket) do
    socket =
      socket.assigns.glossary_entry_editing?
      |> persist_glossary_entry(socket.assigns.editing_glossary_entry, normalize_attrs(attrs))
      |> handle_glossary_entry_result(socket)

    {:noreply, socket}
  end

  def handle_event("sort", %{"field" => field}, socket) when field in @sortable_fields do
    sort = %{
      "field" => field,
      "direction" => ListContext.next_sort_direction(socket.assigns.sort, field)
    }

    socket =
      socket
      |> assign(:sort, sort)
      |> load_glossary_entries(1, current_page_size(socket, :glossary_entries_metadata))

    {:noreply, socket}
  end

  def handle_event("sort", _params, socket), do: {:noreply, socket}

  def handle_event("restore-list-context", context, socket) when is_map(context) do
    filters = context |> Map.take(@filter_keys) |> normalize_filters()

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:sort, normalize_sort(context["sort"]))
      |> load_glossary_entries(
        normalize_page(context["page"]),
        normalize_page_size(context["page_size"])
      )

    {:noreply, socket}
  end

  defp load_glossary_entries(socket, page, page_size) do
    %{entries: glossary_entries, metadata: glossary_entries_metadata} =
      Translations.list_glossary_entries(
        page: page,
        per_page: page_size,
        filter: socket.assigns.filters,
        sort: socket.assigns.sort,
        preloads: [:domain]
      )

    socket
    |> assign(:glossary_entries, glossary_entries)
    |> assign(:glossary_entries_metadata, glossary_entries_metadata)
    |> assign(
      :list_context_payload,
      list_context_payload(socket.assigns.filters, page, page_size, socket.assigns.sort)
    )
  end

  defp list_context_payload(filters, page, page_size, sort) do
    pagination =
      if page > 1 do
        %{"page" => Integer.to_string(page)}
      else
        %{}
      end

    filters
    |> Map.merge(pagination)
    |> maybe_put_page_size(page_size)
    |> maybe_put_sort(sort)
    |> ListContext.payload(@available_params)
  end

  defp maybe_put_page_size(payload, @default_page_size), do: payload

  defp maybe_put_page_size(payload, page_size),
    do: Map.put(payload, "page_size", Integer.to_string(page_size))

  defp maybe_put_sort(payload, %{"field" => _field, "direction" => _direction} = sort),
    do: Map.put(payload, "sort", sort)

  defp maybe_put_sort(payload, _sort), do: payload

  defp normalize_sort(%{"field" => field, "direction" => direction})
       when field in @sortable_fields and direction in ["asc", "desc"] do
    %{"field" => field, "direction" => direction}
  end

  defp normalize_sort(_sort), do: %{}

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

  defp normalize_page(page) do
    case Integer.parse(to_string(page || "1")) do
      {page, ""} when page > 0 -> page
      _invalid -> 1
    end
  end

  defp normalize_page_size(page_size) do
    case Integer.parse(to_string(page_size || @default_page_size)) do
      {page_size, ""} when page_size > 0 -> page_size
      _invalid -> @default_page_size
    end
  end

  defp normalize_pagination(%{"page" => page, "page_size" => page_size}),
    do: {normalize_page(page), normalize_page_size(page_size)}

  defp normalize_pagination(%{"page" => page}),
    do: {normalize_page(page), @default_page_size}

  defp normalize_pagination(%{"index" => page}),
    do: {normalize_page(page), @default_page_size}

  defp normalize_pagination(_params), do: {1, @default_page_size}

  defp get_glossary_entry(id) do
    case parse_id_filter(id) do
      {:ok, id} ->
        Translations.get_glossary_entry(
          filter: [id: id],
          preloads: [:domain]
        )

      _invalid ->
        {:error, :id, :invalid}
    end
  end

  defp persist_glossary_entry(true, %GlossaryEntry{} = glossary_entry, attrs) do
    Translations.update_glossary_entry(glossary_entry, attrs)
  end

  defp persist_glossary_entry(false, %GlossaryEntry{}, attrs) do
    Translations.create_glossary_entry(attrs)
  end

  defp handle_glossary_entry_result({:ok, _glossary_entry}, socket) do
    socket
    |> clear_glossary_entry_editor()
    |> load_glossary_entries(
      current_page(socket, :glossary_entries_metadata),
      current_page_size(socket, :glossary_entries_metadata)
    )
  end

  defp handle_glossary_entry_result({:error, changeset}, socket) do
    assign(socket, :glossary_entry_form, to_form(changeset))
  end

  defp assign_glossary_entry_editor(socket, %GlossaryEntry{} = glossary_entry, editing?) do
    socket
    |> assign(:editing_glossary_entry, glossary_entry)
    |> assign(:glossary_entry_form, to_form(Translations.change_glossary_entry(glossary_entry)))
    |> assign(:glossary_entry_editing?, editing?)
  end

  defp clear_glossary_entry_editor(socket) do
    socket
    |> assign(:editing_glossary_entry, nil)
    |> assign(:glossary_entry_form, nil)
    |> assign(:glossary_entry_editing?, false)
  end

  defp assign_scope_options(socket) do
    %{entries: domains} = Translations.list_domains(per_page: @scope_options_limit)

    assign(socket, :domains, domains)
  end

  defp normalize_attrs(attrs) do
    attrs
    |> normalize_locale_attr("source_locale")
    |> normalize_locale_attr("target_locale")
    |> normalize_optional_id("domain_id")
  end

  defp normalize_locale_attr(attrs, key) do
    Map.update(attrs, key, nil, fn
      nil -> nil
      value -> value |> String.trim() |> String.downcase()
    end)
  end

  defp normalize_optional_id(attrs, key) do
    Map.update(attrs, key, nil, fn
      "" -> nil
      value -> value
    end)
  end

  defp current_page(socket, metadata_key) do
    socket.assigns
    |> Map.get(metadata_key, %{page_number: 1})
    |> Map.get(:page_number, 1)
  end

  defp current_page_size(socket, metadata_key) do
    socket.assigns
    |> Map.get(metadata_key, %{page_size: @default_page_size})
    |> Map.get(:page_size, @default_page_size)
  end
end
