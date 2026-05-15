defmodule ExLingo.AI.Translations.Plugin.FormComponent do
  @moduledoc """
  Translation form component for AI suggestions.
  """

  use ExLingoWeb, :live_component

  alias ExLingo.AI.Translations.{Plugin, Suggestions}

  def update(assigns, socket) do
    provider_options = Suggestions.provider_options()
    selected_provider = List.first(provider_options)

    socket =
      socket
      |> assign(assigns)
      |> assign(:provider_options, provider_options)
      |> assign(:source_locale, Plugin.source_locale())
      |> assign_new(:selected_provider_id, fn -> selected_provider && selected_provider.id end)
      |> assign_new(:selected_model, fn ->
        selected_provider && selected_provider.default_model
      end)
      |> assign_new(:suggestion, fn -> nil end)
      |> assign_new(:adapted_text, fn -> nil end)
      |> assign_new(:adapting?, fn -> false end)
      |> assign_new(:loading?, fn -> false end)
      |> assign_new(:error, fn -> nil end)

    {:ok, socket}
  end

  def handle_event("request_suggestion", %{"ai_suggestion" => params}, socket) do
    provider_id = Map.get(params, "provider_id")
    model = Map.get(params, "model")

    message = socket.assigns.message
    locale = socket.assigns.locale
    translation = socket.assigns.translation
    source_locale = socket.assigns.source_locale

    socket =
      socket
      |> assign(:loading?, true)
      |> assign(:error, nil)
      |> assign(:selected_provider_id, provider_id)
      |> assign(:selected_model, model)
      |> start_async(:ai_suggestion, fn ->
        Suggestions.suggest(
          message,
          locale,
          translation,
          provider_id: provider_id,
          source_locale: source_locale,
          model: model
        )
      end)

    {:noreply, socket}
  end

  def handle_event("request_suggestion", _params, socket) do
    {:noreply, assign(socket, :error, t("Invalid AI suggestion form data."))}
  end

  def handle_event("accept_suggestion", _params, %{assigns: %{suggestion: suggestion}} = socket)
      when is_binary(suggestion) do
    socket =
      case Suggestions.accept_suggestion(socket.assigns.translation, suggestion) do
        {:ok, translation} ->
          after_accept(socket, translation)

        {:error, reason} ->
          assign(socket, :error, error_message(reason))
      end

    {:noreply, socket}
  end

  def handle_event("adapt_suggestion", _params, socket) do
    {:noreply, assign(socket, :adapting?, true)}
  end

  def handle_event(
        "save_adapted_suggestion",
        %{"ai_suggestion" => %{"adapted_text" => text}},
        socket
      ) do
    socket =
      case Suggestions.accept_suggestion(socket.assigns.translation, text) do
        {:ok, translation} ->
          after_accept(socket, translation)

        {:error, reason} ->
          assign(socket, :error, error_message(reason))
      end

    {:noreply, socket}
  end

  def handle_async(:ai_suggestion, {:ok, {:ok, suggestion}}, socket) do
    socket =
      socket
      |> assign(:suggestion, suggestion)
      |> assign(:adapted_text, suggestion)
      |> assign(:adapting?, false)
      |> assign(:loading?, false)
      |> assign(:error, nil)

    {:noreply, socket}
  end

  def handle_async(:ai_suggestion, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:loading?, false)
     |> assign(:error, error_message(reason))}
  end

  def handle_async(:ai_suggestion, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:loading?, false)
     |> assign(:error, error_message(reason))}
  end

  def selected_provider(assigns) do
    Enum.find(assigns.provider_options, &(&1.id == assigns.selected_provider_id)) ||
      List.first(assigns.provider_options)
  end

  def error_message(:provider_not_configured), do: t("No AI translation provider is configured.")

  def error_message({:invalid_provider, provider}),
    do: t("Invalid AI provider: %{provider}.", provider: inspect(provider))

  def error_message({:missing_api_key, _provider}), do: t("The AI provider API key is missing.")

  def error_message({:invalid_model, model}),
    do: t("Model %{model} is not allowed for this provider.", model: model)

  def error_message(reason),
    do: t("Could not generate a suggestion: %{reason}", reason: inspect(reason))

  def loading?(assigns), do: Map.get(assigns, :loading?, false)

  defp after_accept(%{assigns: %{return_to: :parent}} = socket, translation) do
    send(self(), {:ai_suggestion_accepted, socket.assigns.message.id})

    socket
    |> assign(:translation, translation)
    |> assign(:suggestion, nil)
    |> assign(:adapted_text, nil)
    |> assign(:adapting?, false)
  end

  defp after_accept(socket, _translation) do
    push_navigate(socket, to: translation_path(socket))
  end

  defp translation_path(socket) do
    message = socket.assigns.message
    locale = socket.assigns.locale
    translation = socket.assigns.translation

    path = "/locales/#{locale.id}/translations/#{message.id}"

    case translation do
      %{nplural_index: index} when is_integer(index) ->
        dashboard_path(socket, path <> "?tab=#{index + 1}")

      _translation ->
        dashboard_path(socket, path)
    end
  end
end
