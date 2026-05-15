defmodule ExLingoWeb.Translations.PossibleDuplicatesLive do
  use ExLingoWeb, :live_view

  alias ExLingo.Translations
  alias ExLingo.Translations.Locale

  import ExLingoWeb.Translations.PossibleDuplicateComponents,
    only: [possible_duplicate_details: 1]

  @locales_limit 500

  def mount(params, _session, socket) do
    %{entries: locales} = Translations.list_locales(per_page: @locales_limit)
    selected_locale = selected_locale(locales, params["locale_id"])

    socket =
      socket
      |> assign(:locales, locales)
      |> assign(:selected_locale, selected_locale)
      |> assign(:filters, %{"locale_id" => locale_id(selected_locale)})
      |> load_candidates()

    {:ok, socket}
  end

  def handle_event("filter", %{"locale_id" => locale_id}, socket) do
    selected_locale = selected_locale(socket.assigns.locales, locale_id)

    socket =
      socket
      |> assign(:selected_locale, selected_locale)
      |> assign(:filters, %{"locale_id" => locale_id(selected_locale)})
      |> load_candidates()

    {:noreply, socket}
  end

  def handle_event("filter", %{"filters" => %{"locale_id" => locale_id}}, socket) do
    handle_event("filter", %{"locale_id" => locale_id}, socket)
  end

  def handle_event("filter", _params, socket), do: {:noreply, socket}

  defp load_candidates(%{assigns: %{selected_locale: %Locale{id: locale_id}}} = socket) do
    candidates = Translations.list_possible_duplicate_translations(locale_id: locale_id)
    assign(socket, :candidates, candidates)
  end

  defp load_candidates(socket), do: assign(socket, :candidates, [])

  defp selected_locale([], _locale_id), do: nil

  defp selected_locale(locales, locale_id) do
    locale_id = normalize_id(locale_id)

    Enum.find(locales, &(locale_id(&1) == locale_id)) || List.first(locales)
  end

  defp locale_id(%Locale{id: id}), do: id
  defp locale_id(_locale), do: nil

  defp normalize_id(nil), do: nil
  defp normalize_id(id) when is_integer(id), do: id

  defp normalize_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {id, ""} when id > 0 -> id
      _invalid -> nil
    end
  end

  defp normalize_id(_id), do: nil
end
