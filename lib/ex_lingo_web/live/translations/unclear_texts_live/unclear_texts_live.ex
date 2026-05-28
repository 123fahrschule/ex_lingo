defmodule ExLingoWeb.Translations.UnclearTextsLive do
  use ExLingoWeb, :live_view

  alias ExLingo.Translations

  def mount(_params, _session, socket) do
    {:ok, load_messages(socket)}
  end

  def handle_event("refresh", _params, socket) do
    {:noreply, load_messages(socket)}
  end

  defp load_messages(socket) do
    assign(socket, :messages, Translations.list_context_review_messages())
  end

  defp source_reference_label(%{"file" => file, "line" => line}), do: reference_label(file, line)
  defp source_reference_label(%{file: file, line: line}), do: reference_label(file, line)
  defp source_reference_label(reference), do: inspect(reference)

  defp reference_label(file, line) when is_integer(line), do: "#{file}:#{line}"
  defp reference_label(file, line) when is_binary(line) and line != "", do: "#{file}:#{line}"
  defp reference_label(file, _line), do: file
end
