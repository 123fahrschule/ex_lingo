defmodule ExLingoWeb.Dashboard.DashboardLive do
  use ExLingoWeb, :live_view
  require Logger

  alias ExLingo.Cache
  alias ExLingo.PoFiles.MessagesExtractorAgent
  alias ExLingo.PoFiles.Services.StaleDetection.Result
  alias ExLingo.Translations
  alias ExLingo.Translations.Locale.Finders.GetLocaleTranslationProgress

  def mount(_params, _session, socket) do
    messages_count = Translations.get_messages_count()
    stale_messages_count = get_stale_messages_count()
    mergeable_messages_count = get_mergeable_messages_count()
    %{entries: domains, metadata: _domains_metadata} = Translations.list_domains()
    %{entries: locales, metadata: _locales_metadata} = Translations.list_locales()
    unclear_messages = Translations.list_context_review_messages()

    socket =
      socket
      |> assign(:messages_count, messages_count)
      |> assign(:stale_messages_count, stale_messages_count)
      |> assign(:mergeable_messages_count, mergeable_messages_count)
      |> assign(:languages, locales)
      |> assign(:domains, domains)
      |> assign(:unclear_messages_count, length(unclear_messages))
      |> assign(:cache_count, cache_count())

    {:ok, socket}
  end

  def handle_event("clear-cache", _, socket) do
    Cache.delete_all()

    {:noreply, assign(socket, :cache_count, cache_count())}
  end

  def handle_event("delete-stale", _, socket) do
    %Result{stale_message_ids: stale_message_ids} =
      MessagesExtractorAgent.get_stale_detection_result()

    case Translations.delete_messages(MapSet.to_list(stale_message_ids)) do
      {:ok, _stats} ->
        result = MessagesExtractorAgent.get_stale_detection_result(true)

        {:noreply,
         socket
         |> assign(:stale_messages_count, result.stale_count)
         |> assign(:mergeable_messages_count, result.mergeable_count)}

      {:error, reason} ->
        Logger.error("failed to delete stale messages: #{inspect(reason)}")

        {:noreply, put_flash(socket, :error, t("Failed to delete stale messages."))}
    end
  end

  # Merge all the orphaned messages to selected target messages (that fuzzy mathed).
  def handle_event("restore-mergeable", _, socket) do
    %Result{fuzzy_matches_map: fuzzy_matches_map} =
      MessagesExtractorAgent.get_stale_detection_result()

    # Merge all messages with fuzzy matches
    Enum.each(fuzzy_matches_map, fn {_stale_id, fuzzy_match} ->
      Translations.merge_messages(fuzzy_match.stale_message_id, fuzzy_match.matched_message_id)
    end)

    result = MessagesExtractorAgent.get_stale_detection_result(true)

    {:noreply,
     socket
     |> assign(:mergeable_messages_count, result.mergeable_count)
     |> assign(:stale_messages_count, result.stale_count)}
  end

  def translation_progress(language) do
    GetLocaleTranslationProgress.find(language.id)
  end

  defp get_stale_messages_count do
    %Result{stale_count: stale_count} =
      MessagesExtractorAgent.get_stale_detection_result()

    stale_count
  end

  defp get_mergeable_messages_count do
    %Result{mergeable_count: mergeable_count} =
      MessagesExtractorAgent.get_stale_detection_result()

    mergeable_count
  end

  defp cache_count do
    case Cache.count_all() do
      {:ok, count} when is_integer(count) -> count
      count when is_integer(count) -> count
      _other -> 0
    end
  end
end
