defmodule ExLingoWeb.Translations.GlossaryEntryFormLive do
  use ExLingoWeb, :live_view

  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]

  alias ExLingo.Translations
  alias ExLingo.Translations.GlossaryEntry

  @scope_options_limit 100

  def mount(%{"id" => glossary_entry_id}, _session, socket) do
    socket =
      case get_glossary_entry(glossary_entry_id) do
        {:ok, glossary_entry} ->
          socket
          |> assign_form(glossary_entry)
          |> assign(:glossary_entry, glossary_entry)
          |> assign_scope_options()

        _ ->
          redirect(socket, to: dashboard_path(socket, "/glossary"))
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_form(%GlossaryEntry{})
      |> assign_scope_options()

    {:ok, socket}
  end

  def handle_event("validate", %{"glossary_entry" => attrs}, socket) do
    glossary_entry = Map.get(socket.assigns, :glossary_entry, %GlossaryEntry{})
    action = if Map.has_key?(socket.assigns, :glossary_entry), do: :update, else: :insert

    form =
      glossary_entry
      |> Translations.change_glossary_entry(normalize_attrs(attrs))
      |> Map.put(:action, action)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event(
        "submit",
        %{"glossary_entry" => attrs},
        %{assigns: %{glossary_entry: glossary_entry}} = socket
      ) do
    socket =
      case Translations.update_glossary_entry(glossary_entry, normalize_attrs(attrs)) do
        {:ok, _glossary_entry} ->
          push_navigate(socket, to: dashboard_path(socket, "/glossary"))

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("submit", %{"glossary_entry" => attrs}, socket) do
    socket =
      case Translations.create_glossary_entry(normalize_attrs(attrs)) do
        {:ok, _glossary_entry} ->
          push_navigate(socket, to: dashboard_path(socket, "/glossary"))

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  defp assign_form(socket, glossary_entry) do
    assign(socket, :form, to_form(Translations.change_glossary_entry(glossary_entry)))
  end

  defp assign_scope_options(socket) do
    %{entries: domains} = Translations.list_domains(per_page: @scope_options_limit)

    %{entries: application_sources} =
      Translations.list_application_sources(per_page: @scope_options_limit)

    socket
    |> assign(:domains, domains)
    |> assign(:application_sources, application_sources)
  end

  defp get_glossary_entry(id) do
    case parse_id_filter(id) do
      {:ok, id} ->
        Translations.get_glossary_entry(
          filter: [id: id],
          preloads: [:domain, :application_source]
        )

      _ ->
        {:error, :id, :invalid}
    end
  end

  defp normalize_attrs(attrs) do
    attrs
    |> normalize_locale("source_locale")
    |> normalize_locale("target_locale")
    |> normalize_optional_id("domain_id")
    |> normalize_optional_id("application_source_id")
  end

  defp normalize_locale(attrs, key) do
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
end
