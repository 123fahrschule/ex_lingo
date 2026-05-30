defmodule ExLingoWeb.Translations.SingularTranslationForm do
  @moduledoc """
  Inline singular translation editor embedded in each message-list row.

  Renders the editable target next to the source, auto-saves on blur,
  surfaces validation hints, and exposes AI suggestion / glossary / mark
  unclear actions through a per-row menu.
  """

  use ExLingoWeb, :live_component

  alias Phoenix.LiveView.JS

  alias ExLingo.AI.Translations.Suggestions
  alias ExLingo.Translations
  alias ExLingo.Translations.SingularTranslation
  alias ExLingo.Translations.Validations
  alias ExLingoWeb.Translations.GlossaryRedirect

  import ExLingoWeb.Translations.TranslationFormHelpers,
    only: [ai_request_opts: 0, error_message: 1, get_query: 1]

  import ExLingoWeb.Translations.TranslationValidationHints,
    only: [validation_hints: 1, length_border_class: 1]

  import ExLingoWeb.Translations.MessageMetadata,
    only: [source_references: 1, source_reference_label: 1]

  def update(assigns, socket) do
    socket =
      socket
      |> assign_new(:save_state, fn -> :idle end)
      |> assign_new(:ai_open?, fn -> false end)
      |> assign_new(:ai_loading?, fn -> false end)
      |> assign_new(:ai_suggestion, fn -> nil end)
      |> assign_new(:ai_error, fn -> nil end)
      |> assign_new(:message, fn -> assigns.message end)
      |> assign_new(:translation, fn -> assigns.translation end)
      |> assign_new(:form, fn -> build_form(assigns.translation, assigns.message) end)
      |> assign(:locale, assigns.locale)
      |> assign(:filters, Map.get(assigns, :filters))
      |> assign(:ai_available?, Suggestions.provider_options() != [])
      |> assign_length_status()

    {:ok, socket}
  end

  def handle_event("validate", %{"translated_text" => translation}, socket) do
    socket =
      socket
      |> update(:form, &Map.merge(&1, %{"translated_text" => translation}))
      |> assign_length_status()

    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    {:noreply, persist(socket)}
  end

  def handle_event("mark_context_unclear", _params, socket) do
    case Translations.mark_message_context_unclear(socket.assigns.message) do
      {:ok, message} ->
        {:noreply,
         socket
         |> assign(:message, message)
         |> put_flash(:info, t("Text marked as unclear."))}

      _error ->
        {:noreply, put_flash(socket, :error, t("Could not mark text as unclear."))}
    end
  end

  def handle_event("open_glossary_for_selection", payload, socket) do
    message = socket.assigns.message
    locale = socket.assigns.locale
    return_to = "/locales/#{locale.id}/translations" <> get_query(socket.assigns)
    query = GlossaryRedirect.query_params(message, locale, payload, return_to)

    {:noreply, push_navigate(socket, to: dashboard_path(socket, "/glossary/new?" <> query))}
  end

  def handle_event("ai_request", _params, socket) do
    message = socket.assigns.message
    locale = socket.assigns.locale
    translation = socket.assigns.translation
    opts = ai_request_opts()

    socket =
      socket
      |> assign(:ai_open?, true)
      |> assign(:ai_loading?, true)
      |> assign(:ai_error, nil)
      |> assign(:ai_suggestion, nil)
      |> start_async(:ai_suggestion, fn ->
        Suggestions.suggest(message, locale, translation, opts)
      end)

    {:noreply, socket}
  end

  def handle_event("ai_accept", _params, %{assigns: %{ai_suggestion: suggestion}} = socket)
      when is_binary(suggestion) do
    socket =
      socket
      |> update(:form, &Map.merge(&1, %{"translated_text" => suggestion}))
      |> assign(:ai_open?, false)
      |> assign(:ai_suggestion, nil)
      |> assign_length_status()
      |> persist()

    {:noreply, socket}
  end

  def handle_event("ai_accept", _params, socket), do: {:noreply, socket}

  def handle_event("ai_dismiss", _params, socket) do
    {:noreply,
     socket
     |> assign(:ai_open?, false)
     |> assign(:ai_suggestion, nil)
     |> assign(:ai_error, nil)}
  end

  def handle_async(:ai_suggestion, {:ok, {:ok, suggestion}}, socket) do
    {:noreply,
     socket
     |> assign(:ai_loading?, false)
     |> assign(:ai_suggestion, suggestion)
     |> assign(:ai_error, nil)}
  end

  def handle_async(:ai_suggestion, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:ai_loading?, false)
     |> assign(:ai_error, error_message(reason))}
  end

  def handle_async(:ai_suggestion, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:ai_loading?, false)
     |> assign(:ai_error, error_message(reason))}
  end

  defp persist(socket) do
    current = socket.assigns.form["translated_text"] || ""
    saved = socket.assigns.translation.translated_text || ""

    if current == saved do
      assign(socket, :save_state, :idle)
    else
      do_persist(socket, current)
    end
  end

  defp do_persist(socket, translated) do
    translation = socket.assigns.translation

    result =
      if is_nil(translation.id) do
        Translations.create_singular_translation(%{
          "message_id" => socket.assigns.message.id,
          "locale_id" => socket.assigns.locale.id,
          "original_text" => socket.assigns.form["original_text"],
          "translated_text" => translated
        })
      else
        Translations.update_singular_translation(translation, %{"translated_text" => translated})
      end

    case result do
      {:ok, translation} ->
        socket
        |> assign(:translation, translation)
        |> assign(:save_state, :saved)

      {:error, _changeset} ->
        socket
        |> assign(:save_state, :error)
        |> put_flash(:error, t("Could not update translation."))
    end
  end

  defp build_form(translation, message) do
    %{
      "original_text" => translation.original_text || message.msgid,
      "translated_text" => translation.translated_text
    }
  end

  defp assign_length_status(socket) do
    source = socket.assigns.form["original_text"] || ""
    target = socket.assigns.form["translated_text"] || ""
    assign(socket, :length_status, Validations.length_status(source, target))
  end

  @doc false
  def transient_translation(message, locale, translations) do
    Enum.find(translations || [], &(&1.locale_id == locale.id)) ||
      %SingularTranslation{message_id: message.id, locale_id: locale.id}
  end
end
