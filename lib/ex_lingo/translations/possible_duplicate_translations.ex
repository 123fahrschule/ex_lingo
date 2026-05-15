defmodule ExLingo.Translations.PossibleDuplicateTranslations do
  @moduledoc """
  Detects possible duplicate translations for dashboard review.

  The detector is read-only. It derives candidate groups from the current
  message and translation tables so users can decide whether application code
  should use a shared gettext message.
  """

  alias ExLingo.Translations
  alias ExLingo.Translations.{Message, PluralTranslation, SingularTranslation}

  @short_source_max_length 60

  defmodule Candidate do
    @moduledoc """
    A possible duplicate translation group.
    """

    @enforce_keys [
      :id,
      :reason,
      :confidence,
      :translation_type,
      :target_text,
      :occurrences
    ]
    defstruct [
      :id,
      :reason,
      :confidence,
      :translation_type,
      :nplural_index,
      :source_text,
      :target_text,
      :occurrence_count,
      :source_texts,
      :message_ids,
      :occurrences
    ]
  end

  defmodule Occurrence do
    @moduledoc """
    One message/translation occurrence inside a duplicate candidate.
    """

    @enforce_keys [
      :message_id,
      :translation_id,
      :translation_type,
      :source_text,
      :target_text
    ]
    defstruct [
      :message_id,
      :translation_id,
      :translation_type,
      :nplural_index,
      :source_text,
      :target_text,
      :normalized_source_text,
      :loose_source_text,
      :normalized_target_text,
      :source_placeholders,
      :target_placeholders,
      :domain,
      :context,
      :application_source,
      :source_references
    ]
  end

  @type confidence :: :high | :medium | :low

  @type reason ::
          :same_source_same_target_different_scope
          | :same_target_different_source
          | :near_source_variant_same_target

  @type candidate :: %Candidate{
          id: String.t(),
          reason: reason(),
          confidence: confidence(),
          translation_type: :singular | :plural,
          nplural_index: integer() | nil,
          source_text: String.t() | nil,
          target_text: String.t(),
          occurrence_count: pos_integer(),
          source_texts: [String.t()],
          message_ids: [integer()],
          occurrences: [Occurrence.t()]
        }

  @type occurrence :: %Occurrence{
          message_id: integer(),
          translation_id: integer(),
          translation_type: :singular | :plural,
          nplural_index: integer() | nil,
          source_text: String.t(),
          target_text: String.t()
        }

  @spec list(keyword() | map()) :: [candidate()]
  def list(params \\ []) do
    params = normalize_params(params)

    case normalize_id(params[:locale_id]) do
      nil ->
        []

      locale_id ->
        locale_id
        |> occurrences()
        |> build_candidates()
    end
  end

  @spec candidates_for_message(keyword() | map()) :: [candidate()]
  def candidates_for_message(params) do
    params = normalize_params(params)
    message_id = normalize_id(params[:message_id])

    params
    |> list()
    |> Enum.filter(&candidate_contains_message?(&1, message_id))
  end

  @spec summaries_by_message(keyword() | map()) :: map()
  def summaries_by_message(params) do
    params = normalize_params(params)
    filter_ids = normalize_id_set(params[:message_ids])

    params
    |> list()
    |> Enum.reduce(%{}, fn candidate, acc ->
      candidate.occurrences
      |> Enum.filter(&include_message?(&1.message_id, filter_ids))
      |> Enum.reduce(acc, &put_summary(&1, candidate, &2))
    end)
  end

  defp occurrences(locale_id) do
    singular_occurrences(locale_id) ++ plural_occurrences(locale_id)
  end

  defp singular_occurrences(locale_id) do
    [
      filter: [locale_id: locale_id],
      preloads: [message: [:domain, :context, :application_source]],
      skip_pagination: true
    ]
    |> Translations.list_singular_translations()
    |> Enum.flat_map(&singular_occurrence/1)
  end

  defp plural_occurrences(locale_id) do
    [
      filter: [locale_id: locale_id],
      preloads: [message: [:domain, :context, :application_source]],
      skip_pagination: true
    ]
    |> Translations.list_plural_translations()
    |> Enum.flat_map(&plural_occurrence/1)
  end

  defp singular_occurrence(%SingularTranslation{message: %Message{} = message} = translation) do
    translation
    |> effective_target_text()
    |> occurrence(:singular, translation.id, nil, message)
  end

  defp singular_occurrence(_translation), do: []

  defp plural_occurrence(%PluralTranslation{message: %Message{} = message} = translation) do
    translation
    |> effective_target_text()
    |> occurrence(:plural, translation.id, translation.nplural_index, message)
  end

  defp plural_occurrence(_translation), do: []

  defp occurrence(nil, _type, _translation_id, _nplural_index, _message), do: []

  defp occurrence(target_text, type, translation_id, nplural_index, message) do
    source_text = message.msgid || ""

    [
      %Occurrence{
        message_id: message.id,
        translation_id: translation_id,
        translation_type: type,
        nplural_index: nplural_index,
        source_text: source_text,
        target_text: target_text,
        normalized_source_text: normalize_text(source_text),
        loose_source_text: normalize_source_variant(source_text),
        normalized_target_text: normalize_text(target_text),
        source_placeholders: placeholders(source_text),
        target_placeholders: placeholders(target_text),
        domain: message.domain,
        context: message.context,
        application_source: message.application_source,
        source_references: source_references(message)
      }
    ]
  end

  defp effective_target_text(%{translated_text: translated_text, original_text: original_text}) do
    first_present_text([translated_text, original_text])
  end

  defp first_present_text(texts) do
    Enum.find_value(texts, fn
      text when is_binary(text) ->
        text = String.trim(text)
        if text == "", do: nil, else: text

      _other ->
        nil
    end)
  end

  defp build_candidates(occurrences) do
    occurrences
    |> exact_source_candidates()
    |> Kernel.++(near_source_candidates(occurrences))
    |> Kernel.++(target_text_candidates(occurrences))
    |> deduplicate_candidates()
    |> Enum.sort_by(&candidate_sort_key/1)
  end

  defp exact_source_candidates(occurrences) do
    occurrences
    |> Enum.group_by(&{type_key(&1), &1.normalized_source_text, &1.normalized_target_text})
    |> candidate_groups(:same_source_same_target_different_scope, :high, &different_scopes?/1)
  end

  defp near_source_candidates(occurrences) do
    occurrences
    |> Enum.group_by(&{type_key(&1), &1.loose_source_text, &1.normalized_target_text})
    |> candidate_groups(:near_source_variant_same_target, :medium, fn group ->
      different_sources?(group) and source_variants_only?(group)
    end)
  end

  defp target_text_candidates(occurrences) do
    occurrences
    |> Enum.filter(&short_source?/1)
    |> Enum.group_by(&{type_key(&1), &1.normalized_target_text})
    |> candidate_groups(:same_target_different_source, :low, &different_sources?/1)
  end

  defp candidate_groups(grouped, reason, confidence, predicate) do
    grouped
    |> Map.values()
    |> Enum.filter(&(length(&1) > 1))
    |> Enum.filter(&compatible_placeholders?/1)
    |> Enum.filter(predicate)
    |> Enum.map(&candidate(&1, reason, confidence))
  end

  defp candidate(occurrences, reason, confidence) do
    occurrences = Enum.sort_by(occurrences, &{&1.source_text, &1.message_id, &1.translation_id})
    first = List.first(occurrences)
    source_texts = occurrences |> Enum.map(& &1.source_text) |> Enum.uniq() |> Enum.sort()
    message_ids = occurrences |> Enum.map(& &1.message_id) |> Enum.uniq() |> Enum.sort()

    %Candidate{
      id: candidate_id(reason, first, occurrences),
      reason: reason,
      confidence: confidence,
      translation_type: first.translation_type,
      nplural_index: first.nplural_index,
      source_text: if(length(source_texts) == 1, do: List.first(source_texts)),
      target_text: first.target_text,
      occurrence_count: length(occurrences),
      source_texts: source_texts,
      message_ids: message_ids,
      occurrences: occurrences
    }
  end

  defp deduplicate_candidates(candidates) do
    {deduplicated, _seen} =
      Enum.reduce(candidates, {[], MapSet.new()}, fn candidate, {acc, seen} ->
        key = candidate_occurrence_key(candidate)

        if MapSet.member?(seen, key) do
          {acc, seen}
        else
          {[candidate | acc], MapSet.put(seen, key)}
        end
      end)

    Enum.reverse(deduplicated)
  end

  defp candidate_occurrence_key(candidate) do
    occurrence_ids =
      candidate.occurrences
      |> Enum.map(&{&1.translation_type, &1.nplural_index, &1.translation_id})
      |> Enum.sort()

    {candidate.translation_type, candidate.nplural_index, candidate.target_text, occurrence_ids}
  end

  defp candidate_id(reason, occurrence, occurrences) do
    hash_source =
      [
        reason,
        occurrence.translation_type,
        occurrence.nplural_index,
        occurrence.normalized_target_text,
        occurrences |> Enum.map(& &1.translation_id) |> Enum.sort() |> Enum.join(",")
      ]
      |> Enum.join("|")

    hash =
      :sha256
      |> :crypto.hash(hash_source)
      |> Base.url_encode64(padding: false)
      |> binary_part(0, 12)

    "#{reason}-#{hash}"
  end

  defp candidate_sort_key(candidate) do
    {confidence_rank(candidate.confidence), candidate.target_text, candidate.source_text || "",
     candidate.id}
  end

  defp confidence_rank(:high), do: 0
  defp confidence_rank(:medium), do: 1
  defp confidence_rank(:low), do: 2

  defp compatible_placeholders?(occurrences) do
    occurrences
    |> Enum.map(&{&1.source_placeholders, &1.target_placeholders})
    |> Enum.uniq()
    |> length()
    |> Kernel.==(1)
  end

  defp different_scopes?(occurrences) do
    occurrences
    |> Enum.map(&scope_key/1)
    |> Enum.uniq()
    |> length()
    |> Kernel.>(1)
  end

  defp different_sources?(occurrences) do
    occurrences
    |> Enum.map(& &1.normalized_source_text)
    |> Enum.uniq()
    |> length()
    |> Kernel.>(1)
  end

  defp source_variants_only?(occurrences) do
    occurrences
    |> Enum.map(& &1.loose_source_text)
    |> Enum.uniq()
    |> length()
    |> Kernel.==(1)
  end

  defp short_source?(occurrence) do
    occurrence.source_text
    |> String.length()
    |> Kernel.<=(@short_source_max_length)
  end

  defp type_key(%Occurrence{translation_type: :plural, nplural_index: nplural_index}) do
    {:plural, nplural_index}
  end

  defp type_key(%Occurrence{translation_type: :singular}), do: {:singular, nil}

  defp scope_key(occurrence) do
    {
      relation_id(occurrence.domain),
      relation_id(occurrence.context),
      relation_id(occurrence.application_source)
    }
  end

  defp relation_id(%{id: id}), do: id
  defp relation_id(_relation), do: nil

  defp normalize_text(text) when is_binary(text) do
    text
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  defp normalize_text(_text), do: ""

  defp normalize_source_variant(text) do
    text
    |> normalize_text()
    |> String.downcase()
    |> String.replace(~r/[\s[:punct:]]+$/u, "")
  end

  defp placeholders(text) when is_binary(text) do
    ~r/%\{([A-Za-z_][A-Za-z0-9_]*)\}/
    |> Regex.scan(text, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp placeholders(_text), do: []

  defp source_references(%Message{source_references: references}) when is_list(references) do
    references
    |> Enum.filter(&source_reference?/1)
    |> Enum.uniq()
  end

  defp source_references(_message), do: []

  defp source_reference?(%{"file" => file}) when is_binary(file), do: true
  defp source_reference?(%{file: file}) when is_binary(file), do: true
  defp source_reference?(_reference), do: false

  defp candidate_contains_message?(_candidate, nil), do: false

  defp candidate_contains_message?(candidate, message_id) do
    Enum.any?(candidate.occurrences, &(&1.message_id == message_id))
  end

  defp put_summary(occurrence, candidate, acc) do
    Map.update(
      acc,
      occurrence.message_id,
      new_summary(candidate),
      &update_summary(&1, candidate)
    )
  end

  defp new_summary(candidate) do
    %{
      count: 1,
      highest_confidence: candidate.confidence,
      reasons: [candidate.reason],
      candidates: [candidate]
    }
  end

  defp update_summary(summary, candidate) do
    %{
      summary
      | count: summary.count + 1,
        highest_confidence: highest_confidence(summary.highest_confidence, candidate.confidence),
        reasons: Enum.uniq(summary.reasons ++ [candidate.reason]),
        candidates: Enum.uniq_by(summary.candidates ++ [candidate], & &1.id)
    }
  end

  defp highest_confidence(current, candidate) do
    [current, candidate]
    |> Enum.min_by(&confidence_rank/1)
  end

  defp include_message?(_message_id, nil), do: true
  defp include_message?(message_id, message_ids), do: MapSet.member?(message_ids, message_id)

  defp normalize_params(params) when is_map(params) do
    params
    |> Enum.map(fn
      {key, value} when is_binary(key) -> {normalize_param_key(key), value}
      pair -> pair
    end)
    |> Enum.reject(fn {key, _value} -> is_nil(key) end)
    |> Map.new()
  end

  defp normalize_params(params) when is_list(params), do: Map.new(params)

  defp normalize_param_key("locale_id"), do: :locale_id
  defp normalize_param_key("message_id"), do: :message_id
  defp normalize_param_key("message_ids"), do: :message_ids
  defp normalize_param_key(_key), do: nil

  defp normalize_id(nil), do: nil
  defp normalize_id(id) when is_integer(id), do: id

  defp normalize_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {id, ""} when id > 0 -> id
      _invalid -> nil
    end
  end

  defp normalize_id(_id), do: nil

  defp normalize_id_set(nil), do: nil

  defp normalize_id_set(ids) when is_list(ids) do
    ids
    |> Enum.map(&normalize_id/1)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  defp normalize_id_set(ids), do: normalize_id_set([ids])
end
