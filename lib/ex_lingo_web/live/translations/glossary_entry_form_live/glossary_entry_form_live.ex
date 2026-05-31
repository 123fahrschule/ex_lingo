defmodule ExLingoWeb.Translations.GlossaryEntryFormLive do
  use ExLingoWeb, :live_view

  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]

  alias ExLingo.Translations
  alias ExLingo.Translations.GlossaryEntry

  @scope_options_limit 100

  def mount(%{"id" => glossary_entry_id} = params, _session, socket) do
    socket =
      case get_glossary_entry(glossary_entry_id) do
        {:ok, glossary_entry} ->
          socket
          |> assign_form(glossary_entry)
          |> assign(:glossary_entry, glossary_entry)
          |> assign_scope_options()
          |> assign_return_to(params)

        _ ->
          redirect(socket, to: dashboard_path(socket, "/glossary"))
      end

    {:ok, socket}
  end

  def mount(params, _session, socket) do
    initial_attrs = initial_attrs_from_params(params)

    socket =
      socket
      |> assign(
        :form,
        %GlossaryEntry{}
        |> Translations.change_glossary_entry(initial_attrs)
        |> to_form()
      )
      |> assign_scope_options()
      |> assign_return_to(params)

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
          redirect_after_save(socket)

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("submit", %{"glossary_entry" => attrs}, socket) do
    socket =
      case Translations.create_glossary_entry(normalize_attrs(attrs)) do
        {:ok, _glossary_entry} ->
          redirect_after_save(socket)

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, redirect_after_save(socket)}
  end

  defp assign_form(socket, glossary_entry) do
    assign(socket, :form, to_form(Translations.change_glossary_entry(glossary_entry)))
  end

  defp assign_return_to(socket, params) do
    assign(socket, :return_to, params["return_to"])
  end

  defp initial_attrs_from_params(params) do
    %{
      "source_locale" => params["source_locale"],
      "target_locale" => params["target_locale"],
      "source_term" => params["source_term"],
      "target_term" => params["target_term"],
      "domain_id" => params["domain_id"]
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp redirect_after_save(socket) do
    return_to = socket.assigns[:return_to]

    target_path =
      with binary when is_binary(binary) <- return_to,
           {:ok, path} <- safe_dashboard_path(socket, binary) do
        path
      else
        _ -> dashboard_path(socket, "/glossary")
      end

    push_navigate(socket, to: target_path)
  end

  defp assign_scope_options(socket) do
    %{entries: domains} = Translations.list_domains(per_page: @scope_options_limit)

    assign(socket, :domains, domains)
  end

  defp get_glossary_entry(id) do
    case parse_id_filter(id) do
      {:ok, id} ->
        Translations.get_glossary_entry(
          filter: [id: id],
          preloads: [:domain]
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
