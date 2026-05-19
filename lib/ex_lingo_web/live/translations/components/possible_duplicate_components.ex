defmodule ExLingoWeb.Translations.PossibleDuplicateComponents do
  @moduledoc """
  Shared UI for possible duplicate translation candidates.
  """

  use ExLingoWeb, :component

  attr :candidates, :list, default: []
  attr :current_message_id, :integer, default: nil
  attr :compact, :boolean, default: false

  def possible_duplicate_details(assigns) do
    assigns =
      assigns
      |> assign(:candidates, List.wrap(assigns[:candidates]))
      |> assign(:candidate_count, length(List.wrap(assigns[:candidates])))

    ~H"""
    <section
      :if={@candidates != []}
      class={[
        "rounded-md border border-info-300 bg-info-50/60",
        @compact && "space-y-3 p-3",
        !@compact && "space-y-5 p-5"
      ]}
      data-possible-duplicate-details
    >
      <div class="flex flex-wrap items-center justify-between gap-2">
        <div>
          <div class="text-body-sm font-semibold text-foreground">
            {t("Possible duplicate")}
          </div>
          <p class="text-body-xs text-muted-foreground">
            {t("This translation may be shared with other active messages.")}
          </p>
        </div>
        <.badge variant="secondary" class="border-info-300 bg-info-100 text-info-500">
          {length(@candidates)}
        </.badge>
      </div>

      <div class={if @compact, do: "grid gap-3", else: "grid gap-5"}>
        <article
          :for={{candidate, index} <- Enum.with_index(@candidates)}
          class={[
            "rounded-md border border-border bg-background",
            @compact && "space-y-3 p-3",
            !@compact && "space-y-4 p-5 shadow-sm"
          ]}
          style={candidate_spacing_style(index, @candidate_count, @compact)}
          data-possible-duplicate-candidate-id={candidate.id}
        >
          <div class="flex flex-wrap items-start justify-between gap-3">
            <div class="flex flex-wrap items-center gap-2">
              <.badge variant="outline" class="uppercase">
                {translation_type_label(candidate)}
              </.badge>
              <.badge variant="secondary" class={confidence_badge_class(candidate.confidence)}>
                {confidence_label(candidate.confidence)}
              </.badge>
              <.badge variant="secondary" class="border-info-300 bg-info-100 text-info-500">
                {reason_label(candidate.reason)}
              </.badge>
            </div>

            <.tooltip id={"ai-duplicate-instruction-copy-#{candidate.id}"} class="inline-flex">
              <.button
                type="button"
                variant="outline"
                size="sm"
                phx-click={copy_ai_instruction(candidate)}
                class="shrink-0"
                data-copy-feedback-target="true"
              >
                <.icon name="content_copy" size="sm" decorative />
                {t("Copy AI instructions")}
              </.button>
              <.tooltip_content side="top" align="end">
                {t("Copied!")}
              </.tooltip_content>
            </.tooltip>
          </div>

          <div class="grid gap-3 md:grid-cols-2">
            <div class="min-w-0">
              <div class="text-body-xs font-medium uppercase text-muted-foreground">
                {t("Effective translation")}
              </div>
              <div class="break-words text-body-sm font-medium text-foreground">
                {candidate.target_text}
              </div>
            </div>

            <div class="min-w-0">
              <div class="text-body-xs font-medium uppercase text-muted-foreground">
                {t("Source strings")}
              </div>
              <div class="space-y-1">
                <div :for={source_text <- candidate.source_texts} class="break-words text-body-sm text-foreground">
                  {source_text}
                </div>
              </div>
            </div>
          </div>

          <div :if={candidate.translation_type == :plural} class="text-body-xs text-muted-foreground">
            {t("Plural form")}: <span class="text-foreground">{candidate.nplural_index}</span>
          </div>

          <details
            class="group rounded-md border border-border bg-muted/20"
            style={if @compact, do: "padding: 0.75rem;", else: "padding: 1rem;"}
          >
            <summary class="cursor-pointer text-body-sm font-medium text-foreground">
              {t("Related messages")} ({candidate.occurrence_count})
            </summary>
            <div class="mt-3">
              <div
                :for={{occurrence, occurrence_index} <- Enum.with_index(candidate.occurrences)}
                class={[
                  "rounded-md border border-border bg-background",
                  @current_message_id == occurrence.message_id && "bg-info-50"
                ]}
                style={
                  occurrence_card_style(
                    occurrence_index,
                    length(candidate.occurrences),
                    @compact
                  )
                }
              >
                <div class="flex flex-wrap items-center gap-2">
                  <.badge variant="outline">
                    {t("Message")} #{occurrence.message_id}
                  </.badge>
                  <span class="text-body-xs text-muted-foreground">
                    {scope_label(occurrence)}
                  </span>
                </div>
                <div class="mt-2 grid gap-2 md:grid-cols-2">
                  <div class="min-w-0 text-body-xs">
                    <span class="font-medium text-muted-foreground">{t("MsgID")}:</span>
                    <span class="break-words text-foreground">{occurrence.source_text}</span>
                  </div>
                  <div class="min-w-0 text-body-xs">
                    <span class="font-medium text-muted-foreground">{t("Effective translation")}:</span>
                    <span class="break-words text-foreground">{occurrence.target_text}</span>
                  </div>
                </div>
                <div :if={occurrence.source_references != []} class="mt-2">
                  <div class="text-body-xs font-medium text-muted-foreground">
                    {t("Source references")}
                  </div>
                  <ul class="mt-1 space-y-1">
                    <li :for={reference <- occurrence.source_references}>
                      <code class="break-all rounded bg-muted px-1.5 py-0.5 text-body-xs text-foreground">
                        {source_reference_label(reference)}
                      </code>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </details>
        </article>
      </div>
    </section>
    """
  end

  def reason_label(:same_source_same_target_different_scope),
    do: t("Same source and translation")

  def reason_label(:same_target_different_source), do: t("Same translation")
  def reason_label(:near_source_variant_same_target), do: t("Source variant")
  def reason_label(_reason), do: t("Possible duplicate")

  def confidence_label(:high), do: t("High confidence")
  def confidence_label(:medium), do: t("Medium confidence")
  def confidence_label(:low), do: t("Low confidence")
  def confidence_label(_confidence), do: t("Possible duplicate")

  def confidence_badge_class(:high), do: "border-warning-300 bg-warning-100 text-warning-500"
  def confidence_badge_class(:medium), do: "border-info-300 bg-info-100 text-info-500"
  def confidence_badge_class(:low), do: "border-muted bg-muted text-muted-foreground"
  def confidence_badge_class(_confidence), do: "border-muted bg-muted text-muted-foreground"

  def copy_ai_instruction(candidate) do
    Phoenix.LiveView.JS.dispatch("cognit:copy",
      detail: %{text: ai_cleanup_instruction(candidate)}
    )
  end

  def ai_cleanup_instruction(candidate) do
    """
    Du arbeitest im Repository der Anwendung, in der diese UI-Texte verwendet werden. Bitte prüfe diese mögliche doppelte Übersetzung im Anwendungscode und bereinige sie nur, wenn die Semantik wirklich vollständig gleich ist.

    Wichtig:
    - Prüfe zuerst die unten genannten Quellpositionen im Anwendungscode. Wenn eine Quellposition fehlt, suche nach dem angegebenen Quelltext.
    - Ziehe Keys nur zusammen, wenn Bedeutung, Nutzungskontext, Platzhalter, Pluralform, Grammatik und spätere Änderungswahrscheinlichkeit vollständig identisch sind.
    - Gleiche Zielübersetzungen allein reichen nicht aus. Wenn ein Text je nach UI-Stelle fachlich anders verstanden werden kann, bleibt er getrennt.
    - Wenn du zusammenziehst, ändere den Anwendungscode so, dass die betroffenen Stellen denselben fachlich passenden i18n-/gettext-Key verwenden. Entferne danach nicht mehr genutzte doppelte Keys/Einträge, sofern das Projekt dafür einen klaren Mechanismus hat.
    - Halte den Patch klein, ändere keine unabhängigen Übersetzungen und führe passende Tests aus.

    Warum diese Stellen auffallen:
    - Typ: #{translation_type_label(candidate)}
    - Sicherheit: #{confidence_label(candidate.confidence)}
    - Grund: #{reason_label(candidate.reason)}
    - Aktuelle Übersetzung: #{quoted(candidate.target_text)}
    #{plural_instruction_line(candidate)}- Quelltexte / Suchbegriffe:
    #{formatted_source_texts(candidate.source_texts)}

    Zu prüfende Stellen:
    #{formatted_app_occurrences(candidate.occurrences)}
    """
    |> String.trim()
  end

  def translation_type_label(%{translation_type: :plural, nplural_index: index}) do
    "#{t("Plural Translation")} #{index}"
  end

  def translation_type_label(%{translation_type: :singular}), do: t("Singular Translation")
  def translation_type_label(_candidate), do: t("Translation")

  def scope_label(occurrence) do
    [
      "#{t("Domain")}: #{relation_name(occurrence.domain, t("None"))}",
      "#{t("Context")}: #{relation_name(occurrence.context, t("None"))}",
      "#{t("Application")}: #{relation_name(occurrence.application_source, t("Global"))}"
    ]
    |> Enum.join(" · ")
  end

  defp relation_name(%{name: name}, _fallback) when is_binary(name) and name != "", do: name
  defp relation_name(_relation, fallback), do: fallback

  defp plural_instruction_line(%{translation_type: :plural, nplural_index: index}) do
    "- Pluralform: #{index}\n"
  end

  defp plural_instruction_line(_candidate), do: ""

  defp formatted_source_texts(source_texts) do
    source_texts
    |> List.wrap()
    |> Enum.map_join("\n", &"      - #{quoted(&1)}")
  end

  defp formatted_app_occurrences(occurrences) do
    occurrences
    |> Enum.with_index(1)
    |> Enum.map_join("\n\n", fn {occurrence, index} ->
      """
      #{index}. Quellpositionen: #{formatted_instruction_source_references(occurrence.source_references)}
         Quelltext / Suchbegriff: #{quoted(occurrence.source_text)}
         Aktuelle Übersetzung: #{quoted(occurrence.target_text)}
         Typ: #{occurrence_type_label(occurrence)}
      """
      |> String.trim_trailing()
    end)
  end

  defp occurrence_type_label(%{translation_type: :plural, nplural_index: index}) do
    "#{t("Plural Translation")} #{index}"
  end

  defp occurrence_type_label(%{translation_type: :singular}), do: t("Singular Translation")
  defp occurrence_type_label(_occurrence), do: t("Translation")

  defp formatted_source_references([]), do: t("None")
  defp formatted_source_references(nil), do: t("None")

  defp formatted_source_references(references) do
    references
    |> List.wrap()
    |> Enum.map(&source_reference_label/1)
    |> Enum.join(", ")
  end

  defp formatted_instruction_source_references([]),
    do: "nicht aufgezeichnet; suche nach dem Quelltext / Suchbegriff"

  defp formatted_instruction_source_references(nil),
    do: "nicht aufgezeichnet; suche nach dem Quelltext / Suchbegriff"

  defp formatted_instruction_source_references(references),
    do: formatted_source_references(references)

  defp quoted(text) when is_binary(text), do: inspect(text, printable_limit: :infinity)
  defp quoted(text), do: inspect(text)

  defp candidate_spacing_style(index, candidate_count, _compact)
       when index >= candidate_count - 1,
       do: nil

  defp candidate_spacing_style(_index, _candidate_count, true), do: "margin-bottom: 0.75rem;"
  defp candidate_spacing_style(_index, _candidate_count, false), do: "margin-bottom: 1.5rem;"

  defp occurrence_card_style(index, occurrence_count, compact) do
    padding = if compact, do: "0.75rem", else: "1rem"
    margin = if index >= occurrence_count - 1, do: "0", else: occurrence_card_margin(compact)

    "padding: #{padding}; margin-bottom: #{margin};"
  end

  defp occurrence_card_margin(true), do: "0.75rem"
  defp occurrence_card_margin(false), do: "1rem"

  defp source_reference_label(%{"file" => file, "line" => line}), do: reference_label(file, line)
  defp source_reference_label(%{file: file, line: line}), do: reference_label(file, line)
  defp source_reference_label(reference), do: inspect(reference)

  defp reference_label(file, line) when is_integer(line), do: "#{file}:#{line}"
  defp reference_label(file, line) when is_binary(line) and line != "", do: "#{file}:#{line}"
  defp reference_label(file, _line), do: file
end
