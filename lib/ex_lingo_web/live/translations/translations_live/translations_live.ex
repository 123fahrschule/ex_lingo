defmodule ExLingoWeb.Translations.TranslationsLive do
  use ExLingoWeb, :live_view

  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]

  require Logger

  alias ExLingo.PoFiles.MessagesExtractorAgent
  alias ExLingo.PoFiles.Services.StaleDetection.Result
  alias ExLingo.Translations
  alias ExLingo.Translations.SingularTranslations.Finders.ListSingularTranslations
  alias ExLingo.Translations.PluralTranslations.Finders.ListPluralTranslations
  alias ExLingoWeb.ListContext

  alias ExLingoWeb.Translations.{
    PluralTranslationForm,
    SingularTranslationForm,
    TranslationEditorLoader
  }

  alias ExLingoWeb.Translations.Components.{FiltersBar, MessagesTable}

  alias ExLingoWeb.Components.Shared.Pagination

  @available_filters ~w(application_source_id domain_id search not_translated stale page page_size)
  @available_params ~w(page page_size search filter sort)
  @list_context_prefixes ~w(search page page_size filter[ sort[ edit_message_id highlight_message_id tab clear_list_context)
  @params_in_filter ~w(application_source_id domain_id not_translated stale)
  @ids_to_parse ~w(application_source_id domain_id locale_id)
  @sortable_fields ~w(msgid message_type)
  @default_sort %{"field" => "msgid", "direction" => "asc"}
  @default_page_size 100

  def mount(%{"locale_id" => locale_id} = params, _session, socket) do
    socket =
      case get_locale(locale_id) do
        {:ok, locale} ->
          # Get system-wide stale detection with fuzzy matching
          stale_result = MessagesExtractorAgent.get_stale_detection_result()

          socket
          |> assign(:locale, locale)
          |> assign_editor_defaults()
          |> assign(
            :list_context_storage_key,
            ListContext.storage_key(socket, "translations:#{locale.id}")
          )
          |> assign(:application_sources_empty?, Translations.application_sources_empty?())
          |> assign(:stale_message_ids, stale_result.stale_message_ids)
          |> assign(:fuzzy_matches, stale_result.fuzzy_matches_map)
          |> assign(get_assigns_from_params(params))

        _ ->
          socket
          |> redirect(to: dashboard_path(socket, "/locales"))
      end

    {:ok, socket}
  end

  def handle_params(%{"locale_id" => _locale_id} = params, _location, socket) do
    socket =
      socket
      |> assign(get_assigns_from_params(params))
      |> load_messages(
        params["filter"] || %{},
        params["search"] || "",
        params["page"] || "1",
        params["page_size"] || @default_page_size,
        params
      )
      |> assign(:list_context_payload, list_context_payload(params))
      |> assign(:list_context_prefixes, @list_context_prefixes)
      |> assign_editor_from_params(params)

    {:noreply, socket}
  end

  def handle_event("restore-list-context", context, socket) when is_map(context) do
    params = restore_context_params(context)

    if params == %{} do
      {:noreply, socket}
    else
      {:noreply,
       push_patch(socket,
         to:
           dashboard_path(
             socket,
             "/locales/#{socket.assigns.locale.id}/translations?" <> URI.encode_query(params)
           )
       )}
    end
  end

  def handle_event("change", filters, socket) do
    filters = Map.put(filters, "page", "1")

    query =
      socket.assigns.filters
      |> Map.merge(filters)
      |> format_filters()
      |> put_sort_param(socket.assigns.sort)
      |> UriQuery.params()

    socket = socket |> assign(:filters, Map.merge(socket.assigns.filters, filters))

    {:noreply,
     push_patch(socket,
       to:
         dashboard_path(
           socket,
           "/locales/#{socket.assigns.locale.id}/translations?" <> URI.encode_query(query)
         )
     )}
  end

  def handle_event("sort", %{"field" => field}, socket) when field in @sortable_fields do
    sort = %{
      "field" => field,
      "direction" => ListContext.next_sort_direction(socket.assigns.sort, field)
    }

    filters = Map.put(socket.assigns.filters, "page", "1")

    query =
      filters
      |> format_filters()
      |> put_sort_param(sort)
      |> UriQuery.params()

    socket =
      socket
      |> assign(:sort, sort)
      |> assign(:filters, filters)
      |> load_messages(
        Map.take(filters, @params_in_filter),
        filters["search"] || "",
        "1",
        filters["page_size"] || @default_page_size,
        sort
      )

    {:noreply,
     push_patch(socket,
       to:
         dashboard_path(
           socket,
           "/locales/#{socket.assigns.locale.id}/translations?" <> URI.encode_query(query)
         )
     )}
  end

  def handle_event("sort", _params, socket), do: {:noreply, socket}

  def handle_event("edit_message", %{"id" => id}, socket) do
    case parse_id_filter(id) do
      {:ok, message_id} ->
        {:noreply,
         push_patch(socket,
           to: translations_list_path(socket, edit_message_id: message_id)
         )}

      _invalid ->
        {:noreply, socket}
    end
  end

  def handle_event("close_translation", _params, socket) do
    highlighted_message_id =
      socket.assigns[:highlighted_message_id] || socket.assigns[:editing_message_id]

    {:noreply,
     push_patch(socket,
       to: translations_list_path(socket, highlight_message_id: highlighted_message_id)
     )}
  end

  def handle_event("navigate", %{"to" => to}, socket) do
    case safe_dashboard_path(socket, to) do
      {:ok, path} -> {:noreply, push_navigate(socket, to: path)}
      :error -> {:noreply, socket}
    end
  end

  def handle_event("page_changed", params, socket) do
    {page, page_size} = parse_pagination(params)

    pagination = %{
      "page" => Integer.to_string(page),
      "page_size" => Integer.to_string(page_size)
    }

    socket =
      socket
      |> assign(
        :filters,
        Map.merge(socket.assigns.filters, pagination)
      )

    query =
      socket.assigns.filters
      |> Map.merge(pagination)
      |> format_filters()
      |> put_sort_param(socket.assigns.sort)
      |> UriQuery.params()

    {:noreply,
     push_patch(socket,
       to:
         dashboard_path(
           socket,
           "/locales/#{socket.assigns.locale.id}/translations?" <> URI.encode_query(query)
         )
     )}
  end

  def handle_info(:refresh_messages, socket) do
    # Re-detect system-wide stale messages with fuzzy matching
    %Result{stale_message_ids: stale_message_ids, fuzzy_matches_map: fuzzy_matches_map} =
      MessagesExtractorAgent.get_stale_detection_result(true)

    socket =
      socket
      |> assign(:stale_message_ids, stale_message_ids)
      |> assign(:fuzzy_matches, fuzzy_matches_map)
      |> load_messages(
        Map.take(socket.assigns.filters, @params_in_filter),
        socket.assigns.filters["search"] || "",
        socket.assigns.filters["page"] || "1",
        socket.assigns.filters["page_size"] || @default_page_size,
        socket.assigns.sort
      )

    {:noreply, socket}
  end

  def handle_info({:translation_saved, message_id}, socket) do
    {:noreply,
     push_patch(socket,
       to: translations_list_path(socket, highlight_message_id: message_id)
     )}
  end

  def handle_info({:ai_suggestion_accepted, message_id}, socket) do
    params = %{
      "edit_message_id" => to_string(message_id),
      "tab" => socket.assigns.editing_tab
    }

    {:noreply, assign_editor_from_params(socket, params)}
  end

  defp get_locale(id) do
    case parse_id_filter(id) do
      {:ok, id} -> Translations.get_locale(filter: [id: id])
      _ -> {:error, :id, :invalid}
    end
  end

  defp load_messages(socket, filters, search, page, page_size, sort) do
    locale_id = to_string(socket.assigns.locale.id)
    preload_filters = %{"locale_id" => locale_id}
    singular_translation_query = ListSingularTranslations.filter_query(preload_filters)
    plural_translation_query = ListPluralTranslations.filter_query(preload_filters)

    filters =
      filters
      |> Map.put("locale_id", locale_id)
      |> Map.put("stale_message_ids", socket.assigns.stale_message_ids)

    %{entries: messages, metadata: messages_metadata} =
      Translations.list_messages(
        search: search || "",
        page: parse_page(page || "1"),
        per_page: parse_page_size(page_size),
        filter: parse_filters(filters),
        sort: normalize_sort(sort),
        preloads: [
          :application_source,
          :domain,
          singular_translations: singular_translation_query,
          plural_translations: plural_translation_query
        ]
      )

    socket
    |> assign(:messages, messages)
    |> assign(:messages_metadata, messages_metadata)
    |> assign(
      :possible_duplicate_summaries,
      possible_duplicate_summaries(socket.assigns.locale.id, messages)
    )
  end

  defp possible_duplicate_summaries(locale_id, messages) do
    message_ids = Enum.map(messages, & &1.id)

    Translations.possible_duplicate_translation_summaries(
      locale_id: locale_id,
      message_ids: message_ids
    )
  end

  defp format_filters(filters) do
    filters
    |> Map.take(@available_filters)
    |> Enum.reject(fn {_, value} -> is_nil(value) or value == "" end)
    |> Enum.reduce([filter: %{}, search: "", page: "1"], &update_filters_acc/2)
  end

  defp update_filters_acc({"search", value}, acc), do: Keyword.put(acc, :search, value)
  defp update_filters_acc({"page", value}, acc), do: Keyword.put(acc, :page, value)
  defp update_filters_acc({"page_size", value}, acc), do: Keyword.put(acc, :page_size, value)

  defp update_filters_acc({"not_translated", value}, acc) do
    Keyword.put(acc, :filter, Map.put(acc[:filter] || %{}, "not_translated", value))
  end

  defp update_filters_acc({"stale", value}, acc) do
    Keyword.put(acc, :filter, Map.put(acc[:filter] || %{}, "stale", value))
  end

  defp update_filters_acc({key, value}, acc) do
    case parse_id_filter(value) do
      {:ok, id} -> Keyword.put(acc, :filter, Map.put(acc[:filter] || %{}, key, id))
      _ -> acc
    end
  end

  defp get_assigns_from_params(params) do
    filters =
      params
      |> Map.take(@available_params)
      |> Enum.reduce(%{}, &assign_filter_from_param/2)

    %{
      not_translated_default: get_not_translated_default_value(params),
      stale_default: get_stale_default_value(params),
      sort: normalize_sort(params),
      filters: filters
    }
  end

  defp assign_filter_from_param({"filter", value}, acc) when is_map(value) do
    Map.merge(acc, Map.take(value, @params_in_filter))
  end

  defp assign_filter_from_param({"search", value}, acc), do: Map.put(acc, "search", value)
  defp assign_filter_from_param({"page", value}, acc), do: Map.put(acc, "page", value)
  defp assign_filter_from_param({"page_size", value}, acc), do: Map.put(acc, "page_size", value)
  defp assign_filter_from_param(_param, acc), do: acc

  defp assign_editor_defaults(socket) do
    socket
    |> assign(:editing_message, nil)
    |> assign(:editing_message_id, nil)
    |> assign(:editing_translations, nil)
    |> assign(:editing_possible_duplicate_candidates, [])
    |> assign(:editing_tab, "1")
    |> assign(:editing_current_tab_index, 0)
    |> assign(:editing_current_url, nil)
    |> assign(:highlighted_message_id, nil)
  end

  defp assign_editor_from_params(socket, %{"edit_message_id" => message_id} = params) do
    {tab, current_tab_index} = normalize_tab(Map.get(params, "tab", "1"))

    case TranslationEditorLoader.load(socket.assigns.locale.id, message_id) do
      {:ok,
       %{
         message: message,
         translations: translations,
         possible_duplicate_candidates: possible_duplicate_candidates
       }} ->
        socket
        |> assign(:editing_message, message)
        |> assign(:editing_message_id, message.id)
        |> assign(:editing_translations, translations)
        |> assign(:editing_possible_duplicate_candidates, possible_duplicate_candidates)
        |> assign(:editing_tab, tab)
        |> assign(:editing_current_tab_index, current_tab_index)
        |> assign(
          :editing_current_url,
          translations_list_path(socket, edit_message_id: message.id)
        )
        |> assign(:highlighted_message_id, message.id)

      error ->
        Logger.error("Failed to load translation editor: #{inspect(error)}")

        socket
        |> assign_editor_defaults()
        |> put_flash(:error, t("Could not load translation."))
    end
  end

  defp assign_editor_from_params(socket, params) do
    socket
    |> assign(:editing_message, nil)
    |> assign(:editing_message_id, nil)
    |> assign(:editing_translations, nil)
    |> assign(:editing_possible_duplicate_candidates, [])
    |> assign(:editing_tab, "1")
    |> assign(:editing_current_tab_index, 0)
    |> assign(:editing_current_url, nil)
    |> assign(
      :highlighted_message_id,
      normalize_highlighted_message_id(params["highlight_message_id"])
    )
  end

  defp normalize_highlighted_message_id(message_id) when is_binary(message_id) do
    case parse_id_filter(message_id) do
      {:ok, id} -> id
      _invalid -> nil
    end
  end

  defp normalize_highlighted_message_id(_message_id), do: nil

  defp list_context_payload(%{"clear_list_context" => _}), do: %{}

  defp list_context_payload(params) do
    params
    |> normalize_restored_filter()
    |> normalize_restored_sort()
    |> ListContext.payload(@available_params)
  end

  defp restore_context_params(context) do
    context
    |> normalize_restored_filter()
    |> normalize_restored_sort()
    |> ListContext.payload(@available_params)
    |> UriQuery.params()
  end

  defp normalize_restored_filter(%{"filter" => filter} = context) when is_map(filter) do
    Map.put(context, "filter", Map.take(filter, @params_in_filter))
  end

  defp normalize_restored_filter(context), do: context

  defp normalize_restored_sort(context) do
    sort = parse_sort(context)

    context =
      context
      |> Map.delete("sort")
      |> Map.delete(:sort)
      |> Map.delete("sort[field]")
      |> Map.delete("sort[direction]")
      |> Map.delete(:"sort[field]")
      |> Map.delete(:"sort[direction]")

    case sort do
      nil -> context
      @default_sort -> context
      sort -> Map.put(context, "sort", sort)
    end
  end

  defp normalize_sort(sort), do: parse_sort(sort) || @default_sort

  defp parse_sort(%{"field" => field, "direction" => direction}) do
    sort_values(field, direction)
  end

  defp parse_sort(%{field: field, direction: direction}) do
    sort_values(field, direction)
  end

  defp parse_sort(%{} = params) do
    nested_sort = Map.get(params, "sort") || Map.get(params, :sort)
    flat_field = Map.get(params, "sort[field]") || Map.get(params, :"sort[field]")
    flat_direction = Map.get(params, "sort[direction]") || Map.get(params, :"sort[direction]")

    parse_sort(nested_sort) || sort_values(flat_field, flat_direction)
  end

  defp parse_sort(_sort), do: nil

  defp sort_values(field, direction)
       when (is_binary(field) or is_atom(field)) and
              (is_binary(direction) or is_atom(direction)) do
    field = to_string(field)
    direction = to_string(direction)

    if field in @sortable_fields and direction in ["asc", "desc"] do
      %{"field" => field, "direction" => direction}
    end
  end

  defp sort_values(_field, _direction), do: nil

  defp put_sort_param(params, sort) do
    case parse_sort(sort) do
      nil -> params
      @default_sort -> params
      sort -> Keyword.put(params, :sort, sort)
    end
  end

  defp translations_list_path(socket, opts) do
    query =
      socket.assigns.filters
      |> format_filters()
      |> put_sort_param(socket.assigns.sort)
      |> put_optional_param(:edit_message_id, opts[:edit_message_id])
      |> put_optional_param(:highlight_message_id, opts[:highlight_message_id])
      |> put_optional_param(:tab, opts[:tab])
      |> UriQuery.params()
      |> URI.encode_query()

    path = "/locales/#{socket.assigns.locale.id}/translations"

    if query == "" do
      dashboard_path(socket, path)
    else
      dashboard_path(socket, path <> "?" <> query)
    end
  end

  defp put_optional_param(params, _key, nil), do: params
  defp put_optional_param(params, _key, ""), do: params
  defp put_optional_param(params, key, value), do: Keyword.put(params, key, value)

  defp get_not_translated_default_value(%{"filter" => filter}) do
    case filter["not_translated"] do
      "true" -> true
      _ -> false
    end
  end

  defp get_not_translated_default_value(_), do: false

  defp get_stale_default_value(%{"filter" => filter}) do
    case filter["stale"] do
      "true" -> true
      _ -> false
    end
  end

  defp get_stale_default_value(_), do: false

  defp parse_filters(filters) do
    Enum.reduce(filters, %{}, &parse_filter/2)
  end

  defp parse_filter({key, value}, acc) when key in @ids_to_parse do
    case parse_id_filter(value) do
      {:ok, id} -> Map.put(acc, key, id)
      _ -> acc
    end
  end

  defp parse_filter({key, value}, acc) do
    Map.put(acc, key, value)
  end

  defp parse_page(page) do
    case Integer.parse(to_string(page)) do
      {page, ""} when page > 0 -> page
      _invalid -> 1
    end
  end

  defp parse_page_size(page_size) do
    case Integer.parse(to_string(page_size)) do
      {page_size, ""} when page_size > 0 -> page_size
      _invalid -> @default_page_size
    end
  end

  defp parse_pagination(%{"page" => page, "page_size" => page_size}),
    do: {parse_page(page), parse_page_size(page_size)}

  defp parse_pagination(%{"page" => page}),
    do: {parse_page(page), @default_page_size}

  defp parse_pagination(%{"index" => page}),
    do: {parse_page(page), @default_page_size}

  defp parse_pagination(_params), do: {1, @default_page_size}

  defp normalize_tab(tab) do
    case Integer.parse(to_string(tab)) do
      {tab, ""} when tab > 0 -> {to_string(tab), tab - 1}
      _invalid -> {"1", 0}
    end
  end

end
