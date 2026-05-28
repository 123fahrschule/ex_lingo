defmodule ExLingoWeb.Translations.TranslationValidationHints do
  @moduledoc """
  Inline warnings shown beneath translation textareas: length status,
  missing placeholders, and sentence-ending mismatches.
  """

  use ExLingoWeb, :component

  alias ExLingo.Translations.Validations

  attr :source, :string, default: ""
  attr :target, :string, default: ""

  def validation_hints(assigns) do
    source = assigns.source || ""
    target = assigns.target || ""

    length_status = Validations.length_status(source, target)
    missing = Validations.missing_placeholders(source, target)
    sentence_mismatch? = Validations.sentence_ending_mismatch?(source, target)
    has_target? = target != ""

    assigns =
      assign(assigns,
        length_status: length_status,
        missing_placeholders: missing,
        sentence_mismatch?: sentence_mismatch?,
        has_target?: has_target?,
        target_length: String.length(target),
        length_diff_percent: length_diff_percent(source, target)
      )

    ~H"""
    <div
      :if={@has_target? and (@length_status != :ok or @missing_placeholders != [] or @sentence_mismatch?)}
      class="mt-1 space-y-1 text-body-xs"
    >
      <div :if={@length_status == :slightly_long} class="text-warning-500">
        {length_hint_text(@length_status, @target_length, @length_diff_percent)}
      </div>
      <div :if={@length_status == :too_long} class="text-destructive">
        {length_hint_text(@length_status, @target_length, @length_diff_percent)}
      </div>

      <div :if={@missing_placeholders != []} class="text-destructive">
        {t("Missing placeholder(s):")}
        <code :for={ph <- @missing_placeholders} class="ml-1 rounded bg-muted px-1 py-0.5">{ph}</code>
      </div>

      <div :if={@sentence_mismatch?} class="text-warning-500">
        {t("Original ends with sentence punctuation but the translation does not match.")}
      </div>
    </div>
    """
  end

  @doc """
  Tailwind border classes to apply to the translation input based on length status.
  """
  def length_border_class(:slightly_long), do: "border-warning-400 focus:border-warning-500"
  def length_border_class(:too_long), do: "border-destructive focus:border-destructive"
  def length_border_class(_status), do: ""

  defp length_hint_text(:slightly_long, target_length, nil) do
    t("%{count} characters — longer than the (empty) original",
      count: target_length
    )
  end

  defp length_hint_text(:slightly_long, target_length, diff_percent) do
    t("%{count} characters, %{percent}% longer than original",
      count: target_length,
      percent: diff_percent
    )
  end

  defp length_hint_text(:too_long, target_length, nil) do
    t("%{count} characters — much longer than the (empty) original; likely breaks UI layout",
      count: target_length
    )
  end

  defp length_hint_text(:too_long, target_length, diff_percent) do
    t("%{count} characters, %{percent}% longer than original — likely breaks UI layout",
      count: target_length,
      percent: diff_percent
    )
  end

  defp length_hint_text(_status, _target_length, _diff_percent), do: ""

  defp length_diff_percent(source, target) do
    source_len = String.length(source)

    if source_len == 0 do
      nil
    else
      target_len = String.length(target)
      round((target_len - source_len) / source_len * 100)
    end
  end
end
