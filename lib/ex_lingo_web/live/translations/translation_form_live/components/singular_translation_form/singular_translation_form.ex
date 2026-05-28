defmodule ExLingoWeb.Translations.SingularTranslationForm do
  @moduledoc """
  Singular translation form component
  """

  use ExLingoWeb, :live_component

  alias ExLingo.Translations
  alias ExLingo.Translations.Validations
  alias ExLingoWeb.Translations.GlossaryRedirect
  import ExLingoWeb.Translations.MessageMetadata, only: [message_metadata: 1]

  import ExLingoWeb.Translations.PossibleDuplicateComponents,
    only: [possible_duplicate_details: 1]

  import ExLingoWeb.Translations.TranslationValidationHints,
    only: [validation_hints: 1, length_border_class: 1]

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:mode, Map.get(assigns, :mode, :page))
      |> assign(
        :possible_duplicate_candidates,
        Map.get(assigns, :possible_duplicate_candidates, [])
      )
      |> assign(:form, %{
        "original_text" => assigns[:translation].original_text,
        "translated_text" => assigns[:translation].translated_text
      })

    {:ok, socket |> assign(assigns) |> assign_length_status()}
  end

  def handle_event("validate", %{"translated_text" => translation}, socket) do
    socket =
      socket
      |> update(:form, &Map.merge(&1, %{"translated_text" => translation}))
      |> assign_length_status()

    {:noreply, socket}
  end

  def handle_event("submit", %{"translated_text" => translated}, socket) do
    locale = socket.assigns.locale
    translation = socket.assigns.translation

    case Translations.update_singular_translation(translation, %{"translated_text" => translated}) do
      {:ok, _translation} ->
        after_success(socket, locale)

      {:error, _changeset} ->
        {:noreply,
         socket
         |> update(:form, &Map.merge(&1, %{"translated_text" => translated}))
         |> put_flash(:error, t("Could not update translation."))}
    end
  end

  def handle_event("open_glossary_for_selection", payload, socket) do
    message = socket.assigns.message
    locale = socket.assigns.locale
    return_to = "/locales/#{locale.id}/translations" <> get_query(socket.assigns)
    query = GlossaryRedirect.query_params(message, locale, payload, return_to)

    {:noreply,
     push_navigate(socket, to: dashboard_path(socket, "/glossary/new?" <> query))}
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

  defp assign_length_status(socket) do
    source = socket.assigns.form["original_text"] || ""
    target = socket.assigns.form["translated_text"] || ""
    assign(socket, :length_status, Validations.length_status(source, target))
  end

  defp after_success(%{assigns: %{return_to: :parent}} = socket, _locale) do
    send(self(), {:translation_saved, socket.assigns.message.id})
    {:noreply, socket}
  end

  defp after_success(socket, locale) do
    {:noreply,
     push_navigate(socket,
       to:
         dashboard_path(
           socket,
           "/locales/#{locale.id}/translations" <> get_query(socket.assigns)
         )
     )}
  end

  defp get_query(%{filters: nil}), do: ""

  defp get_query(%{filters: filters}) do
    query = UriQuery.params(filters)
    "?" <> URI.encode_query(query)
  end
end
