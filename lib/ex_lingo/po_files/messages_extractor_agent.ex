defmodule ExLingo.PoFiles.MessagesExtractorAgent do
  @moduledoc """
  GenServer responsible for extracting messages and translations from .po files
  """

  use GenServer
  require Logger

  alias ExLingo.PoFiles.MessagesExtractor
  alias ExLingo.PoFiles.Services.StaleDetection
  alias ExLingo.PoFiles.Services.StaleDetection.Result

  @stale_detection_timeout 60_000

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %{stale_detection_result: nil, loading: true}, {:continue, :load_messages}}
  end

  @impl true
  def handle_continue(:load_messages, state) do
    {:noreply, load_messages(state)}
  end

  @doc """
  Gets system-wide stale detection data.

  ## Returns

    * `%StaleDetection.Result{}` - contains `:stale_message_ids` as a `MapSet`,
      `:fuzzy_matches_map`, `:stale_count`, and `:mergeable_count`.

  ## Examples

      iex> MessagesExtractorAgent.get_stale_detection_result()
      %ExLingo.PoFiles.Services.StaleDetection.Result{
        stale_message_ids: MapSet.new([1, 2, 3]),
        fuzzy_matches_map: %{},
        stale_count: 3,
        mergeable_count: 0
      }

  """
  def get_stale_detection_result(recalculate \\ false) do
    GenServer.call(
      __MODULE__,
      {:get_stale_detection_result, recalculate},
      @stale_detection_timeout
    )
  end

  @impl true
  def handle_call({:get_stale_detection_result, false}, _from, state) do
    {:reply, state.stale_detection_result || empty_result(), state}
  end

  def handle_call({:get_stale_detection_result, true}, _from, state) do
    case run_stale_detection() do
      {:ok, %Result{} = result} ->
        {:reply, result, %{state | stale_detection_result: result, loading: false}}

      {:error, reason} ->
        Logger.error("stale detection failed: #{inspect(reason)}")
        {:reply, state.stale_detection_result || empty_result(), %{state | loading: false}}

      error ->
        Logger.error("stale detection returned unexpected result: #{inspect(error)}")
        {:reply, state.stale_detection_result || empty_result(), %{state | loading: false}}
    end
  end

  defp message_extractor_available? do
    # Message extractor requires columns added in version 3 of the PostgreSQL migration.
    migrator = ExLingo.Migrations.Postgresql

    migrated_version =
      migrator.migrated_version(%{
        repo: ExLingo.Repo.get_repo(),
        prefix: ExLingo.Repo.configured_prefix() || "public"
      })

    migrated_version >= 3
  rescue
    exception ->
      Logger.error(Exception.format(:error, exception, __STACKTRACE__))
      false
  end

  defp load_messages(state) do
    if message_extractor_available?() do
      with {:ok, _messages} <- run_message_extractor(),
           {:ok, %Result{} = result} <- run_stale_detection() do
        %{state | stale_detection_result: result, loading: false}
      else
        {:error, reason} ->
          Logger.error("message extraction failed: #{inspect(reason)}")
          %{state | stale_detection_result: empty_result(), loading: false}

        error ->
          Logger.error("message extraction returned unexpected result: #{inspect(error)}")
          %{state | stale_detection_result: empty_result(), loading: false}
      end
    else
      %{state | stale_detection_result: empty_result(), loading: false}
    end
  end

  defp empty_result, do: Result.new(MapSet.new(), %{})

  defp run_message_extractor do
    MessagesExtractor.call()
  rescue
    exception -> {:error, Exception.format(:error, exception, __STACKTRACE__)}
  end

  defp run_stale_detection do
    StaleDetection.call()
  rescue
    exception -> {:error, Exception.format(:error, exception, __STACKTRACE__)}
  end
end
