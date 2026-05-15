defmodule ExLingoWeb.Translations.DomainsLive do
  use ExLingoWeb, :live_view

  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]
  import ExLingoWeb.Translations.Components.ColorField, only: [color_field: 1]

  alias ExLingo.Translations
  alias ExLingo.Translations.Domain
  alias ExLingoWeb.ListContext
  alias ExLingoWeb.Translations.DomainsTable

  alias ExLingoWeb.Components.Shared.Pagination

  @sortable_fields ~w(name description color)
  @list_context_prefixes ~w(page page_size sort[)
  @default_page_size 100

  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:list_context_storage_key, ListContext.storage_key(socket, "domains"))
      |> assign(:list_context_prefixes, @list_context_prefixes)
      |> assign(:editing_domain, nil)
      |> assign(:domain_form, nil)
      |> assign(:sort, normalize_sort(params["sort"]))
      |> load_domains(parse_page(params["page"]), parse_page_size(params["page_size"]))

    {:ok, socket}
  end

  def handle_event("navigate", %{"to" => to}, socket) do
    case safe_dashboard_path(socket, to) do
      {:ok, path} -> {:noreply, push_navigate(socket, to: path)}
      :error -> {:noreply, socket}
    end
  end

  def handle_event("page_changed", params, socket) do
    {page, page_size} = parse_pagination(params)
    {:noreply, load_domains(socket, page, page_size)}
  end

  def handle_event("edit_domain", %{"id" => id}, socket) do
    socket =
      case get_domain(id) do
        {:ok, %Domain{} = domain} ->
          assign_domain_editor(socket, domain)

        {:error, _, _reason} ->
          put_flash(socket, :error, t("Could not load domain."))
      end

    {:noreply, socket}
  end

  def handle_event("close_domain_editor", _params, socket) do
    {:noreply, clear_domain_editor(socket)}
  end

  def handle_event("validate_domain", %{"domain" => attrs}, socket) do
    form =
      socket.assigns.editing_domain
      |> Translations.change_domain(attrs)
      |> Map.put(:action, :update)
      |> to_form()

    {:noreply, assign(socket, :domain_form, form)}
  end

  def handle_event("submit_domain", %{"domain" => attrs}, socket) do
    socket =
      case Translations.update_domain(socket.assigns.editing_domain, attrs) do
        {:ok, _domain} ->
          socket
          |> clear_domain_editor()
          |> load_domains(
            current_page(socket, :domains_metadata),
            current_page_size(socket, :domains_metadata)
          )

        {:error, changeset} ->
          assign(socket, :domain_form, to_form(changeset))
      end

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
      |> load_domains(1, current_page_size(socket, :domains_metadata))

    {:noreply, socket}
  end

  def handle_event("sort", _params, socket), do: {:noreply, socket}

  def handle_event("restore-list-context", context, socket) when is_map(context) do
    socket =
      socket
      |> assign(:sort, normalize_sort(context["sort"]))
      |> load_domains(parse_page(context["page"]), parse_page_size(context["page_size"]))

    {:noreply, socket}
  end

  defp load_domains(socket, page, page_size) do
    %{entries: domains, metadata: domains_metadata} =
      Translations.list_domains(page: page, per_page: page_size, sort: socket.assigns.sort)

    socket
    |> assign(:domains, domains)
    |> assign(:domains_metadata, domains_metadata)
    |> assign(:list_context_payload, list_context_payload(page, page_size, socket.assigns.sort))
  end

  defp list_context_payload(page, page_size, sort) do
    %{}
    |> maybe_put_page(page)
    |> maybe_put_page_size(page_size)
    |> maybe_put_sort(sort)
    |> ListContext.payload(["page", "page_size", "sort"])
  end

  defp maybe_put_page(payload, page) when page > 1,
    do: Map.put(payload, "page", Integer.to_string(page))

  defp maybe_put_page(payload, _page), do: payload

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

  defp parse_page(page_number) do
    case Integer.parse(to_string(page_number)) do
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

  defp safe_dashboard_path(socket, to) when is_binary(to) do
    cond do
      String.contains?(to, "://") -> :error
      String.starts_with?(to, "//") -> :error
      String.contains?(to, "..") -> :error
      true -> {:ok, dashboard_path(socket, normalize_path(to))}
    end
  end

  defp safe_dashboard_path(_socket, _to), do: :error

  defp normalize_path("/" <> _ = path), do: path
  defp normalize_path(path), do: "/" <> path

  defp get_domain(id) do
    case parse_id_filter(id) do
      {:ok, id} -> Translations.get_domain(filter: [id: id])
      _invalid -> {:error, :id, :invalid}
    end
  end

  defp assign_domain_editor(socket, %Domain{} = domain) do
    socket
    |> assign(:editing_domain, domain)
    |> assign(:domain_form, to_form(Translations.change_domain(domain)))
  end

  defp clear_domain_editor(socket) do
    socket
    |> assign(:editing_domain, nil)
    |> assign(:domain_form, nil)
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
