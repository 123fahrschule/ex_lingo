defmodule ExLingoWeb.Translations.SingularTranslationForm do
  @moduledoc """
  Singular translation form component
  """

  use ExLingoWeb, :live_component

  alias ExLingo.Translations
  import ExLingoWeb.Translations.MessageMetadata, only: [message_metadata: 1]

  import ExLingoWeb.Translations.PossibleDuplicateComponents,
    only: [possible_duplicate_details: 1]

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

    {:ok, assign(socket, assigns)}
  end

  def handle_event("validate", %{"translated_text" => translation}, socket) do
    {:noreply, update(socket, :form, &Map.merge(&1, %{"translated_text" => translation}))}
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
