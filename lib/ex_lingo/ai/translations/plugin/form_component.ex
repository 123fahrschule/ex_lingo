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
      |> assign_new(:error, fn -> nil end)

    {:ok, socket}
  end

  def handle_event("request_suggestion", %{"ai_suggestion" => params}, socket) do
    provider_id = Map.get(params, "provider_id")
    model = Map.get(params, "model")

    result =
      Suggestions.suggest(
        socket.assigns.message,
        socket.assigns.locale,
        socket.assigns.translation,
        provider_id: provider_id,
        source_locale: socket.assigns.source_locale,
        model: model
      )

    socket =
      case result do
        {:ok, suggestion} ->
          socket
          |> assign(:suggestion, suggestion)
          |> assign(:adapted_text, suggestion)
          |> assign(:adapting?, false)
          |> assign(:error, nil)
          |> assign(:selected_provider_id, provider_id)
          |> assign(:selected_model, model)

        {:error, reason} ->
          socket
          |> assign(:error, error_message(reason))
          |> assign(:selected_provider_id, provider_id)
          |> assign(:selected_model, model)
      end

    {:noreply, socket}
  end

  def handle_event("accept_suggestion", _params, %{assigns: %{suggestion: suggestion}} = socket)
      when is_binary(suggestion) do
    socket =
      case Suggestions.accept_suggestion(socket.assigns.translation, suggestion) do
        {:ok, _translation} ->
          push_navigate(socket, to: translation_path(socket))

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
        {:ok, _translation} ->
          push_navigate(socket, to: translation_path(socket))

        {:error, reason} ->
          assign(socket, :error, error_message(reason))
      end

    {:noreply, socket}
  end

  def selected_provider(assigns) do
    Enum.find(assigns.provider_options, &(&1.id == assigns.selected_provider_id)) ||
      List.first(assigns.provider_options)
  end

  def error_message(:provider_not_configured), do: "No AI translation provider is configured."

  def error_message({:invalid_provider, provider}),
    do: "Invalid AI provider: #{inspect(provider)}."

  def error_message({:missing_api_key, _provider}), do: "The AI provider API key is missing."

  def error_message({:invalid_model, model}),
    do: "Model #{model} is not allowed for this provider."

  def error_message(reason), do: "Could not generate a suggestion: #{inspect(reason)}"

  defp translation_path(socket) do
    message = socket.assigns.message
    locale = socket.assigns.locale
    translation = socket.assigns.translation

    path = "/locales/#{locale.id}/translations/#{message.id}"

    if Map.has_key?(translation, :nplural_index) do
      dashboard_path(socket, path <> "?tab=#{translation.nplural_index + 1}")
    else
      dashboard_path(socket, path)
    end
  end
end
