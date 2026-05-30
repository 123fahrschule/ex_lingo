defmodule ExLingo.Settings do
  @moduledoc """
  Settings context for ExLingo.

  Backed by a single row in `ex_lingo_settings`. The row is created lazily on
  first access and seeded with the historical 123fs translation prompt as the
  global AI system prompt, so upgrading from a hardcoded prompt loses nothing.

  The single row is cached to avoid a database round-trip on every AI request;
  the cache is invalidated on `update/1`.
  """

  import Ecto.Query

  alias ExLingo.Cache
  alias ExLingo.Repo
  alias ExLingo.Settings.Setting

  @cache_key "settings:singleton"
  @row_id 1

  # Default prompt template seeded as the global template on first use. It
  # carries the historical 123fs instructions and renders every value ExLingo
  # sends via {{placeholders}} (see ExLingo.AI.Translations.PromptRenderer), so
  # the whole prompt is visible and editable from the settings page.
  @default_prompt_template """
  You are a translation assistant for software product text in the driving school domain.
  Return only the final translation text.
  Do not include Markdown, labels, quotes, notes, confidence, rationale, or alternatives.
  Follow glossary terminology when relevant.

  Source locale: {{source_locale}}
  Target locale: {{target_locale}}
  Target language name: {{target_locale_name}}
  Message type: {{message_type}}
  Context: {{context}}
  Plural form index: {{plural_form_index}}
  Quantity examples: {{plural_examples}}

  Source text:
  {{source_text}}

  Current translation to improve or replace:
  {{current_translation}}

  Glossary entries to honor when applicable:
  {{glossary}}
  """

  @doc "The built-in prompt template, used to seed the settings row and as a fallback."
  @spec default_prompt_template() :: String.t()
  def default_prompt_template, do: String.trim(@default_prompt_template)

  @doc """
  Returns the settings row, creating and caching it lazily if needed.
  """
  @spec get() :: Setting.t()
  def get do
    case Cache.get(@cache_key) do
      {:ok, %Setting{} = setting} ->
        setting

      _miss ->
        setting = load_or_create()
        Cache.put(@cache_key, setting)
        setting
    end
  end

  @doc """
  Updates the settings row and invalidates the cache.
  """
  @spec update(map()) :: {:ok, Setting.t()} | {:error, Ecto.Changeset.t()}
  def update(attrs) do
    result =
      load_or_create()
      |> Setting.changeset(attrs)
      |> Repo.get_repo().update(Repo.opts())

    case result do
      {:ok, _setting} = ok ->
        Cache.delete(@cache_key)
        ok

      error ->
        error
    end
  end

  @doc """
  Builds a changeset for the settings row (for form rendering).
  """
  @spec change(Setting.t(), map()) :: Ecto.Changeset.t()
  def change(%Setting{} = setting, attrs \\ %{}) do
    Setting.changeset(setting, attrs)
  end

  @doc """
  Returns the AI prompt template for a locale, cascading:
  per-locale override -> global template -> nil (caller falls back to the default).
  """
  @spec prompt_template_for(String.t() | nil) :: String.t() | nil
  def prompt_template_for(locale_code) do
    setting = get()
    per_locale = setting.ai_prompt_template_per_locale || %{}

    cond do
      present?(is_binary(locale_code) && Map.get(per_locale, locale_code)) ->
        Map.get(per_locale, locale_code)

      present?(setting.ai_prompt_template) ->
        setting.ai_prompt_template

      true ->
        nil
    end
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""

  # Translator quality-warning thresholds. Each value cascades:
  # stored override -> app config (`config :ex_lingo, :validations`) -> built-in default.
  @validation_defaults %{
    length_warning_ratio: 1.3,
    length_error_ratio: 1.8,
    short_string_threshold: 10,
    short_abs_warning: 5,
    short_abs_error: 15
  }

  @validation_db_fields %{
    length_warning_ratio: :validation_length_warning_ratio,
    length_error_ratio: :validation_length_error_ratio,
    short_string_threshold: :validation_short_string_threshold,
    short_abs_warning: :validation_short_abs_warning,
    short_abs_error: :validation_short_abs_error
  }

  @doc "Default validation thresholds map, keyed by `config :ex_lingo, :validations` keys."
  @spec validation_defaults() :: map()
  def validation_defaults, do: @validation_defaults

  @doc """
  Returns the effective translator quality-warning thresholds.

  Resolves each value as stored override -> app config -> built-in default.
  Safe to call outside a database context (e.g. pure unit code): if the
  settings store is unreachable it falls back to config/defaults instead of
  raising, because these warnings are advisory.
  """
  @spec validations() :: map()
  def validations do
    setting = safe_get()
    config = Application.get_env(:ex_lingo, :validations, [])

    Map.new(@validation_defaults, fn {key, default} ->
      stored = setting && Map.get(setting, Map.fetch!(@validation_db_fields, key))
      value = if is_number(stored), do: stored, else: Keyword.get(config, key, default)
      {key, value}
    end)
  end

  defp safe_get do
    get()
  rescue
    _error in [DBConnection.OwnershipError, DBConnection.ConnectionError] -> nil
  end

  defp load_or_create do
    repo = Repo.get_repo()

    case repo.one(from(s in Setting, order_by: [asc: s.id], limit: 1), Repo.opts()) do
      %Setting{} = setting ->
        setting

      nil ->
        create_default(repo)
    end
  end

  defp create_default(repo) do
    %Setting{}
    |> Setting.changeset(%{ai_prompt_template: default_prompt_template()})
    |> Ecto.Changeset.put_change(:id, @row_id)
    |> repo.insert(Repo.opts(on_conflict: :nothing, conflict_target: :id))

    repo.get!(Setting, @row_id, Repo.opts())
  end
end
