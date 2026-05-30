defmodule ExLingo.Translations.Validations do
  @moduledoc """
  Pure helpers for translator-facing quality warnings.

  All checks are advisory: they produce a status or a list, never block saving.
  Thresholds live under `config :ex_lingo, :validations, ...` so they can be
  tuned per project (mobile UIs are stricter on length than web UIs).
  """

  @placeholder_regex ~r/%\{[^}]+\}/
  @sentence_endings [".", "!", "?", ":", ";"]

  @default_warning_ratio 1.3
  @default_error_ratio 1.8
  @default_short_threshold 10
  @default_short_warning_abs 5
  @default_short_error_abs 15

  @type length_status :: :ok | :slightly_long | :too_long

  @spec length_status(binary, binary) :: length_status
  def length_status(source, target) when is_binary(source) and is_binary(target) do
    source_len = String.length(source)
    target_len = String.length(target)

    cond do
      target_len == 0 -> :ok
      source_len == 0 -> length_status_for_empty_source(target_len)
      source_len < short_threshold() -> length_status_absolute(source_len, target_len)
      true -> length_status_ratio(source_len, target_len)
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

  defp length_status_for_empty_source(target_len) do
    cond do
      target_len <= short_warning_abs() -> :ok
      target_len <= short_error_abs() -> :slightly_long
      true -> :too_long
    end
  end

  defp length_status_absolute(source_len, target_len) do
    diff = target_len - source_len

    cond do
      diff <= short_warning_abs() -> :ok
      diff <= short_error_abs() -> :slightly_long
      true -> :too_long
    end
  end

  defp length_status_ratio(source_len, target_len) do
    ratio = target_len / source_len

    cond do
      ratio < warning_ratio() -> :ok
      ratio < error_ratio() -> :slightly_long
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

  defp config, do: Application.get_env(:ex_lingo, :validations, [])

  defp warning_ratio,
    do: Keyword.get(config(), :length_warning_ratio, @default_warning_ratio)

  defp error_ratio,
    do: Keyword.get(config(), :length_error_ratio, @default_error_ratio)

  defp short_threshold,
    do: Keyword.get(config(), :short_string_threshold, @default_short_threshold)

  defp short_warning_abs,
    do: Keyword.get(config(), :short_abs_warning, @default_short_warning_abs)

  defp short_error_abs,
    do: Keyword.get(config(), :short_abs_error, @default_short_error_abs)
end
