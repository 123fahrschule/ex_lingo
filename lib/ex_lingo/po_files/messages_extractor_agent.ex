defmodule ExLingo.PoFiles.MessagesExtractorAgent do
  @moduledoc """
  GenServer responsible for extracting messages and translations from .po files
  """

  use GenServer
  alias ExLingo.PoFiles.MessagesExtractor
  alias ExLingo.PoFiles.Services.StaleDetection

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_) do
    state =
      if message_extractor_available?() do
        {:ok, _messages} = MessagesExtractor.call()

        # Detect stale translations system-wide with fuzzy matching
        {:ok, %StaleDetection.Result{} = result} = StaleDetection.call()

        %{stale_detection_result: result}
      else
        %{stale_detection_result: nil}
      end

    {:ok, state}
  end

  @doc """
  Gets system-wide stale message IDs.

  ## Returns

    * `MapSet.t()` - Set of stale message IDs, or empty MapSet

  ## Examples

      iex> MessagesExtractorAgent.get_stale_message_ids()
      #MapSet<[1, 2, 3]>

  """
  def get_stale_detection_result(recalculate \\ false) do
    GenServer.call(__MODULE__, {:get_stale_detection_result, recalculate})
  end

  @impl true
  def handle_call({:get_stale_detection_result, false}, _from, state) do
    {:reply, state.stale_detection_result, state}
  end

  def handle_call({:get_stale_detection_result, true}, _from, state) do
    {:ok, %StaleDetection.Result{} = result} = StaleDetection.call()

    {:reply, result, %{state | stale_detection_result: result}}
  end

  defp message_extractor_available? do
    # Message extractor requires columns added in version 3 of the PostgreSQL migration.
    ExLingo.Repo.get_adapter_name()
    migrator = ExLingo.Migrations.Postgresql

    migrated_version =
      migrator.migrated_version(%{
        repo: ExLingo.Repo.get_repo(),
        prefix: ExLingo.Repo.configured_prefix() || "public"
      })

    migrated_version >= 3
  end
end
