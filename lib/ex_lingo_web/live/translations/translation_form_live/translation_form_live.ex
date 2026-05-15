defmodule ExLingoWeb.Translations.TranslationFormLive do
  use ExLingoWeb, :live_view

  alias ExLingo.Translations.Message

  alias ExLingoWeb.Translations.{
    PluralTranslationForm,
    SingularTranslationForm,
    TranslationEditorLoader
  }

  def render(%{message: %Message{message_type: :singular}} = assigns) do
    ~H"""
      <.live_component
        module={SingularTranslationForm}
        id="singular-translation-form"
        translation={@translations}
        message={@message}
        locale={@locale}
        filters={@filters}
        mode={:page}
      />
    """
  end

  def render(%{message: %Message{message_type: :plural}} = assigns) do
    assigns =
      assigns
      |> assign_new(:tab, fn -> "1" end)
      |> assign_new(:current_tab_index, fn -> 0 end)

    ~H"""
      <.live_component
        module={PluralTranslationForm}
        id="plural-translation-form"
        translations={@translations}
        message={@message}
        locale={@locale}
        current_tab={@tab}
        current_tab_index={@current_tab_index}
        filters={@filters}
        mode={:page}
        current_url={dashboard_path(@socket, "/locales/#{@locale.id}/translations/#{@message.id}")}
      />
    """
  end

  def mount(%{"message_id" => message_id, "locale_id" => locale_id} = params, _session, socket) do
    socket =
      with {:ok, %{locale: locale, message: message, translations: translations}} <-
             TranslationEditorLoader.load(locale_id, message_id) do
        socket
        |> assign(:locale, locale)
        |> assign(:message, message)
        |> assign(:translations, translations)
      else
        _ -> redirect(socket, to: dashboard_path(socket, "/locales/#{locale_id}/translations"))
      end

    {:ok, assign(socket, :filters, Map.get(params, "filters"))}
  end

  def handle_params(%{"tab" => tab}, _uri, socket) do
    {tab, current_tab_index} = normalize_tab(tab)

    {:noreply,
     socket
     |> assign(:tab, tab)
     |> assign(:current_tab_index, current_tab_index)}
  end

  def handle_params(_params, _uri, socket) do
    {tab, current_tab_index} = normalize_tab("1")

    {:noreply,
     socket
     |> assign(:tab, tab)
     |> assign(:current_tab_index, current_tab_index)}
  end

  defp normalize_tab(tab) do
    case Integer.parse(to_string(tab)) do
      {tab, ""} when tab > 0 -> {to_string(tab), tab - 1}
      _invalid -> {"1", 0}
    end
  end
end
