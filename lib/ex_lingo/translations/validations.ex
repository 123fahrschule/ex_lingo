defmodule ExLingo.Translations.Validations do
  @moduledoc """
  Helpers for translator-facing quality warnings.

  All checks are advisory: they produce a status or a list, never block saving.
  Length thresholds are read from `ExLingo.Settings.validations/0`, which lets
  them be tuned from the settings page (mobile UIs are stricter on length than
  web UIs) and cascades to `config :ex_lingo, :validations` and built-in
  defaults.
  """

  alias ExLingo.Settings

  @placeholder_regex ~r/%\{[^}]+\}/
  @sentence_endings [".", "!", "?", ":", ";"]

  @type length_status :: :ok | :slightly_long | :too_long

  @spec length_status(binary, binary) :: length_status
  def length_status(source, target) when is_binary(source) and is_binary(target) do
    source_len = String.length(source)
    target_len = String.length(target)
    thresholds = Settings.validations()

    cond do
      target_len == 0 ->
        :ok

      source_len == 0 ->
        length_status_for_empty_source(target_len, thresholds)

      source_len < thresholds.short_string_threshold ->
        length_status_absolute(source_len, target_len, thresholds)

      true ->
        length_status_ratio(source_len, target_len, thresholds)
    end
  end

  @spec missing_placeholders(binary, binary) :: [binary]
  def missing_placeholders(source, target) when is_binary(source) and is_binary(target) do
    target_set = MapSet.new(extract_placeholders(target))

    source
    |> extract_placeholders()
    |> Enum.uniq()
    |> Enum.reject(&MapSet.member?(target_set, &1))
  end

  @spec sentence_ending_mismatch?(binary, binary) :: boolean
  def sentence_ending_mismatch?(source, target) when is_binary(source) and is_binary(target) do
    if String.trim(target) == "" do
      false
    else
      sentence_ending(source) != sentence_ending(target)
    end
  end

  defp length_status_for_empty_source(target_len, thresholds) do
    cond do
      target_len <= thresholds.short_abs_warning -> :ok
      target_len <= thresholds.short_abs_error -> :slightly_long
      true -> :too_long
    end
  end

  defp length_status_absolute(source_len, target_len, thresholds) do
    diff = target_len - source_len

    cond do
      diff <= thresholds.short_abs_warning -> :ok
      diff <= thresholds.short_abs_error -> :slightly_long
      true -> :too_long
    end
  end

  defp length_status_ratio(source_len, target_len, thresholds) do
    ratio = target_len / source_len

    cond do
      ratio < thresholds.length_warning_ratio -> :ok
      ratio < thresholds.length_error_ratio -> :slightly_long
      true -> :too_long
    end
  end

  defp extract_placeholders(text) do
    @placeholder_regex
    |> Regex.scan(text)
    |> Enum.map(&hd/1)
  end

  defp sentence_ending(text) do
    last = text |> String.trim_trailing() |> String.last()
    if last in @sentence_endings, do: last
  end
end
