defmodule ExLingoWeb.Translations.PluralTranslationForm do
  @moduledoc """
  Plural translation form component
  """

  use ExLingoWeb, :live_component

  alias ExLingo.Translations
  alias ExLingo.Translations.Validations
  alias ExLingo.Utils.ModuleUtils
  alias ExLingoWeb.Components.Shared.Tabs
  alias ExLingoWeb.Translations.GlossaryRedirect
  import ExLingoWeb.Translations.MessageMetadata, only: [message_metadata: 1]

  import ExLingoWeb.Translations.PossibleDuplicateComponents,
    only: [possible_duplicate_details: 1]

  import ExLingoWeb.Translations.TranslationValidationHints,
    only: [validation_hints: 1, length_border_class: 1]

  def update(assigns, socket) do
    valid_plugins = valid_plugins()

    tabs =
      Enum.map(
        assigns.translations,
        &%{
          index: &1.nplural_index + 1,
          label: t("Form %{number}", number: &1.nplural_index + 1)
        }
      )

    translation =
      assigns.translations
      |> Enum.find(&(&1.nplural_index == assigns.current_tab_index))

    form =
      if is_nil(translation),
        do: nil,
        else: %{
          "id" => translation.id,
          "nplural_index" => translation.nplural_index,
          "original_text" => translation.original_text,
          "translated_text" => translation.translated_text
        }

    socket =
      socket
      |> assign(:mode, Map.get(assigns, :mode, :page))
      |> assign(:current_url, Map.get(assigns, :current_url))
      |> assign(
        :possible_duplicate_candidates,
        Map.get(assigns, :possible_duplicate_candidates, [])
      )
      |> assign(:tabs, tabs)
      |> assign(:translation, translation)
      |> assign(:form, form)
      |> assign(:valid_plugins, valid_plugins)

    {:ok, socket |> assign(assigns) |> assign_length_status()}
  end

  def handle_event("validate", attrs, socket) do
    translated =
      attrs
      |> Map.drop(["_target"])
      |> Enum.find_value("", fn
        {"translated_text" <> _suffix, value} -> value
        {_key, value} -> value
      end)

    socket =
      socket
      |> update(:form, &Map.merge(&1, %{"translated_text" => translated}))
      |> assign_length_status()

    {:noreply, socket}
  end

  def handle_event("submit", attrs, socket) do
    locale = socket.assigns.locale

    with {key, translated} <- translated_text_field(attrs),
         "translated_text." <> nplural_index <- key,
         {nplural_index, ""} <- Integer.parse(nplural_index),
         translation when not is_nil(translation) <-
           Enum.find(socket.assigns.translations, &(&1.nplural_index == nplural_index)),
         {:ok, _translation} <-
           Translations.update_plural_translation(translation, %{"translated_text" => translated}) do
      after_success(socket, locale)
    else
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, t("Could not update plural translation."))}

      _invalid ->
        {:noreply, put_flash(socket, :error, t("Invalid plural translation form data."))}
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

  defp assign_length_status(%{assigns: %{form: nil}} = socket),
    do: assign(socket, :length_status, :ok)

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

  def plural_examples(%{plurals_header: plurals_header}, index) when is_binary(plurals_header) do
    case Expo.PluralForms.parse(plurals_header) do
      {:ok, forms_struct} ->
        Enum.group_by(0..100, &Expo.PluralForms.index(forms_struct, &1), & &1)
        |> Map.get(index, [])
        |> Enum.join(", ")

      _error ->
        ""
    end
  end

  def plural_examples(_locale, _index), do: ""

  defp translated_text_field(attrs) do
    Enum.find(attrs, fn
      {key, _value} -> String.starts_with?(key, "translated_text.")
    end)
  end

  defp valid_plugins do
    ExLingo.config().plugins
    |> Enum.map(fn {plugin_name, _opts} ->
      {plugin_name, Module.concat(plugin_name, FormComponent)}
    end)
    |> Enum.filter(fn {_plugin_name, component} -> ModuleUtils.module_exists?(component) end)
  end

  defp get_query(%{filters: nil}), do: ""

  defp get_query(%{filters: filters}) do
    query = UriQuery.params(filters)
    "?" <> URI.encode_query(query)
  end
end
