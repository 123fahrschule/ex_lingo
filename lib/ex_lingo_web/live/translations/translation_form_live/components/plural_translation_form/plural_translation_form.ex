defmodule ExLingoWeb.Translations.PluralTranslationForm do
  @moduledoc """
  Inline plural translation editor embedded in each message-list row.

  Renders every plural form stacked, each with its own auto-saving input,
  validation hints and AI suggestion, plus shared glossary / mark-unclear
  actions for the row.
  """

  use ExLingoWeb, :live_component

  alias Phoenix.LiveView.JS

  alias ExLingo.AI.Translations.Suggestions
  alias ExLingo.Translations
  alias ExLingo.Translations.PluralTranslation
  alias ExLingo.Translations.Validations
  alias ExLingoWeb.Translations.Components.GlossaryEntryFlyout

  import ExLingoWeb.Translations.TranslationFormHelpers,
    only: [ai_request_opts: 0, error_message: 1]

  import ExLingoWeb.Translations.TranslationValidationHints,
    only: [validation_hints: 1, length_border_class: 1]

  def update(assigns, socket) do
    socket =
      socket
      |> assign_new(:message, fn -> assigns.message end)
      |> assign_new(:translations, fn ->
        Enum.sort_by(assigns.translations, & &1.nplural_index)
      end)
      |> assign_new(:ai_index, fn -> nil end)
      |> assign_new(:ai_loading?, fn -> false end)
      |> assign_new(:ai_suggestion, fn -> nil end)
      |> assign_new(:ai_error, fn -> nil end)
      |> assign(:locale, assigns.locale)
      |> assign(:filters, Map.get(assigns, :filters))
      |> assign(:ai_available?, Suggestions.provider_options() != [])
      |> ensure_form_state()

    {:ok, socket}
  end

  def handle_event("validate", %{"translated_text" => text, "index" => index}, socket) do
    {:noreply, put_form_value(socket, parse_index(index), text)}
  end

  def handle_event("save", %{"index" => index}, socket) do
    {:noreply, persist(socket, parse_index(index))}
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
    attrs =
      GlossaryEntryFlyout.prefill_attrs(socket.assigns.message, socket.assigns.locale, payload)

    send(self(), {:open_glossary_flyout, attrs})

    {:noreply, socket}
  end

  def handle_event("ai_request", %{"index" => index}, socket) do
    index = parse_index(index)

    case translation_for(socket, index) do
      nil ->
        {:noreply, socket}

      translation ->
        message = socket.assigns.message
        locale = socket.assigns.locale
        opts = ai_request_opts()

        socket =
          socket
          |> assign(:ai_index, index)
          |> assign(:ai_loading?, true)
          |> assign(:ai_error, nil)
          |> assign(:ai_suggestion, nil)
          |> start_async(:ai_suggestion, fn ->
            Suggestions.suggest(message, locale, translation, opts)
          end)

        {:noreply, socket}
    end
  end

  def handle_event(
        "ai_accept",
        _params,
        %{assigns: %{ai_suggestion: suggestion, ai_index: index}} = socket
      )
      when is_binary(suggestion) and is_integer(index) do
    socket =
      socket
      |> put_form_value(index, suggestion)
      |> assign(:ai_index, nil)
      |> assign(:ai_suggestion, nil)
      |> persist(index)

    {:noreply, socket}
  end

  def handle_event("ai_accept", _params, socket), do: {:noreply, socket}

  def handle_event("ai_dismiss", _params, socket) do
    {:noreply,
     socket
     |> assign(:ai_index, nil)
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

  defp ensure_form_state(socket) do
    socket
    |> assign_new(:forms, fn ->
      build_forms(socket.assigns.translations, socket.assigns.message)
    end)
    |> assign_new(:length_status, fn ->
      build_length_status(socket.assigns.translations, socket.assigns.message)
    end)
    |> assign_new(:save_state, fn ->
      Map.new(socket.assigns.translations, &{&1.nplural_index, :idle})
    end)
  end

  defp build_forms(translations, message) do
    Map.new(translations, fn translation ->
      {translation.nplural_index,
       %{
         "original_text" => translation.original_text || message.msgid,
         "translated_text" => translation.translated_text
       }}
    end)
  end

  defp build_length_status(translations, message) do
    Map.new(translations, fn translation ->
      source = translation.original_text || message.msgid || ""
      target = translation.translated_text || ""
      {translation.nplural_index, Validations.length_status(source, target)}
    end)
  end

  defp put_form_value(socket, index, text) do
    forms =
      Map.update(
        socket.assigns.forms,
        index,
        %{"original_text" => "", "translated_text" => text},
        fn form ->
          Map.put(form, "translated_text", text)
        end
      )

    source = get_in(forms, [index, "original_text"]) || ""
    status = Validations.length_status(source, text || "")

    socket
    |> assign(:forms, forms)
    |> assign(:length_status, Map.put(socket.assigns.length_status, index, status))
  end

  defp persist(socket, index) do
    case translation_for(socket, index) do
      nil ->
        socket

      translation ->
        current = get_in(socket.assigns.forms, [index, "translated_text"]) || ""
        saved = translation.translated_text || ""

        if current == saved do
          put_save_state(socket, index, :idle)
        else
          do_persist(socket, translation, index, current)
        end
    end
  end

  defp do_persist(socket, translation, index, translated) do
    result =
      if is_nil(translation.id) do
        Translations.create_plural_translation(%{
          "message_id" => socket.assigns.message.id,
          "locale_id" => socket.assigns.locale.id,
          "nplural_index" => index,
          "original_text" => get_in(socket.assigns.forms, [index, "original_text"]),
          "translated_text" => translated
        })
      else
        Translations.update_plural_translation(translation, %{"translated_text" => translated})
      end

    case result do
      {:ok, translation} ->
        socket
        |> replace_translation(translation)
        |> put_save_state(index, :saved)

      {:error, _changeset} ->
        socket
        |> put_save_state(index, :error)
        |> put_flash(:error, t("Could not update plural translation."))
    end
  end

  defp replace_translation(socket, translation) do
    translations =
      socket.assigns.translations
      |> Enum.reject(&(&1.nplural_index == translation.nplural_index))
      |> Kernel.++([translation])
      |> Enum.sort_by(& &1.nplural_index)

    assign(socket, :translations, translations)
  end

  defp translation_for(socket, index) do
    Enum.find(socket.assigns.translations, &(&1.nplural_index == index))
  end

  defp put_save_state(socket, index, state) do
    assign(socket, :save_state, Map.put(socket.assigns.save_state, index, state))
  end

  defp parse_index(index) when is_integer(index), do: index

  defp parse_index(index) when is_binary(index) do
    case Integer.parse(index) do
      {value, ""} -> value
      _invalid -> 0
    end
  end

  @doc """
  Builds the plural translation structs (persisted + transient placeholders)
  for a message/locale, one per plural form, sorted by index.
  """
  def transient_translations(message, locale, plural_translations) do
    existing = Enum.filter(plural_translations || [], &(&1.locale_id == locale.id))

    locale
    |> plural_indices(existing)
    |> Enum.map(fn index ->
      Enum.find(existing, &(&1.nplural_index == index)) ||
        %PluralTranslation{message_id: message.id, locale_id: locale.id, nplural_index: index}
    end)
  end

  defp plural_indices(locale, existing) do
    case Expo.PluralForms.parse(locale.plurals_header || "") do
      {:ok, %{nplurals: nplurals}} when nplurals > 0 ->
        0..(nplurals - 1)

      _invalid ->
        case existing do
          [] -> [0, 1]
          translations -> translations |> Enum.map(& &1.nplural_index) |> Enum.sort()
        end
    end
  end
end
