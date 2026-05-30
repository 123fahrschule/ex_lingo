defmodule ExLingo.AI.Translations.PromptRenderer do
  @moduledoc """
  Renders an AI prompt template into the exact text sent to a translation
  provider.

  The template is plain text with `{{placeholder}}` tokens that are replaced
  with values from a `SuggestionRequest`. This puts the whole prompt — both the
  instructions and the data ExLingo knows about (source text, locales, context,
  glossary, …) — under the operator's control in one place.

  Two placeholders are mandatory because the model cannot translate without
  them: `{{source_text}}` and `{{target_locale}}`. If a template leaves either
  out, the missing value is appended automatically so the request stays valid.
  """

  alias ExLingo.AI.Translations.SuggestionRequest

  @placeholders ~w(
    source_text
    source_locale
    target_locale
    target_locale_name
    context
    message_type
    current_translation
    glossary
    plural_form_index
    plural_examples
  )

  @required ~w(source_text target_locale)

  @none "(none)"

  @doc "All placeholder names usable in a template (without the surrounding braces)."
  @spec placeholders() :: [String.t()]
  def placeholders, do: @placeholders

  @doc "Placeholders whose value is always sent to the provider, even if omitted from the template."
  @spec required_placeholders() :: [String.t()]
  def required_placeholders, do: @required

  @doc """
  Renders `template` against `request`, substituting placeholders and ensuring
  the mandatory fields are present in the output.
  """
  @spec render(String.t(), SuggestionRequest.t()) :: String.t()
  def render(template, %SuggestionRequest{} = request) when is_binary(template) do
    values = values(request)

    template
    |> substitute(values)
    |> append_missing_required(template, values)
  end

  defp substitute(template, values) do
    Enum.reduce(values, template, fn {key, value}, acc ->
      String.replace(acc, "{{#{key}}}", value)
    end)
  end

  # Guarantee the minimum the model needs, even if the template omits it.
  defp append_missing_required(rendered, template, values) do
    appendix =
      @required
      |> Enum.reject(&String.contains?(template, "{{#{&1}}}"))
      |> Enum.map(fn key -> {key, values[key]} end)
      |> Enum.reject(fn {_key, value} -> value in [nil, "", @none] end)
      |> Enum.map_join("\n", fn {key, value} -> "#{label(key)}: #{value}" end)

    if appendix == "", do: rendered, else: rendered <> "\n\n" <> appendix
  end

  defp label("source_text"), do: "Source text"
  defp label("target_locale"), do: "Target locale"

  defp values(%SuggestionRequest{} = request) do
    %{
      "source_text" => blank_to_none(request.source_text),
      "source_locale" => blank_to_none(request.source_locale),
      "target_locale" => blank_to_none(request.target_locale),
      "target_locale_name" => blank_to_none(request.target_locale_name),
      "context" => blank_to_none(context(request)),
      "message_type" => blank_to_none(message_type(request)),
      "current_translation" => current_translation(request),
      "glossary" => glossary(request.glossary_entries),
      "plural_form_index" => plural_form_index(request),
      "plural_examples" => blank_to_none(request.plural_examples)
    }
  end

  defp context(%SuggestionRequest{message_metadata: metadata}) when is_map(metadata) do
    Map.get(metadata, :context)
  end

  defp context(_request), do: nil

  defp message_type(%SuggestionRequest{message_type: nil}), do: nil
  defp message_type(%SuggestionRequest{message_type: type}), do: to_string(type)

  defp plural_form_index(%SuggestionRequest{plural_form_index: index}) when is_integer(index) do
    Integer.to_string(index)
  end

  defp plural_form_index(_request), do: @none

  defp current_translation(%SuggestionRequest{current_translation: current})
       when is_map(current) do
    current |> Map.get(:translated_text) |> blank_to_none()
  end

  defp current_translation(_request), do: @none

  defp glossary([]), do: @none

  defp glossary(entries) when is_list(entries) do
    Enum.map_join(entries, "\n", fn entry ->
      "- #{entry.source_term} => #{entry.target_term}#{guidance(entry)}"
    end)
  end

  defp glossary(_entries), do: @none

  defp guidance(%{usage_guidance: guidance}) when is_binary(guidance) do
    case String.trim(guidance) do
      "" -> ""
      trimmed -> " (#{trimmed})"
    end
  end

  defp guidance(_entry), do: ""

  defp blank_to_none(value) when is_binary(value) do
    if String.trim(value) == "", do: @none, else: value
  end

  defp blank_to_none(_value), do: @none
end
