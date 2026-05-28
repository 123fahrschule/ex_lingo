defmodule ExLingoWeb.Translations.MessageMetadata do
  @moduledoc """
  Shared compact metadata block for translation forms.
  """

  use ExLingoWeb, :component

  attr :message, :map, required: true
  attr :translation, :any, default: nil
  attr :mark_target, :any, default: nil
  attr :glossary_target, :any, default: nil
  attr :glossary_button_id, :string, default: "add-to-glossary"

  def message_metadata(assigns) do
    assigns =
      assigns
      |> assign(:source_references, source_references(assigns.message))
      |> assign(:translation_id, translation_id(assigns.translation))

    ~H"""
    <section
      class="space-y-2.5 border-b border-border pb-3 text-body-xs text-muted-foreground"
      data-message-id={@message.id}
      data-translation-id={@translation_id}
    >
      <div class="flex items-start justify-between gap-3">
        <div class="grid min-w-0 gap-1.5">
          <div class="flex min-w-0 items-baseline gap-2">
            <div class="w-20 shrink-0">{t("Domain")}</div>
            <div class="min-w-0 truncate font-medium text-foreground">
              {relation_name(@message.domain, "default")}
            </div>
          </div>
          <div class="flex min-w-0 items-baseline gap-2">
            <div class="w-20 shrink-0">{t("Context")}</div>
            <div class="min-w-0 whitespace-pre-wrap font-medium text-foreground">
              {context_label(@message.context)}
            </div>
          </div>
        </div>
        <div class="flex shrink-0 flex-wrap items-center gap-2">
          <.button
            :if={@glossary_target}
            id={@glossary_button_id}
            type="button"
            variant="outline"
            size="sm"
            phx-hook="ExLingoGlossaryCapture"
            phx-target={@glossary_target}
            title={t("Create a glossary entry from the selected source/target text")}
          >
            <.icon name="book" size="sm" decorative /> {t("Add to glossary")}
          </.button>
          <.button
            :if={@mark_target}
            type="button"
            variant={if @message.context_review_requested_at, do: "secondary", else: "outline"}
            size="sm"
            phx-click="mark_context_unclear"
            phx-target={@mark_target}
            disabled={not is_nil(@message.context_review_requested_at)}
            title={t("Mark this text as unclear for developers")}
          >
            {if @message.context_review_requested_at, do: t("Marked unclear"), else: t("Unclear text")}
          </.button>
        </div>
      </div>

      <div class="space-y-0.5">
        <div class="font-medium uppercase text-muted-foreground">{t("MsgID")}</div>
        <div class="break-words text-body-sm font-medium text-foreground">{@message.msgid}</div>
      </div>

      <dl class="grid grid-cols-2 gap-x-4 gap-y-0.5">
        <div class="flex min-w-0 gap-1.5">
          <dt>{t("Type")}</dt>
          <dd class="min-w-0 capitalize text-foreground">{@message.message_type}</dd>
        </div>
        <div class="flex min-w-0 gap-1.5">
          <dt>{t("Application")}</dt>
          <dd class="min-w-0 truncate text-foreground">
            {relation_name(@message.application_source, t("Global"))}
          </dd>
        </div>
      </dl>

      <details :if={@source_references != []} class="group">
        <summary class="cursor-pointer text-muted-foreground">
          {t("Source Positions")} ({length(@source_references)})
        </summary>
        <ul class="mt-2 space-y-1">
          <li :for={reference <- @source_references}>
            <code class="break-all rounded bg-muted px-1.5 py-0.5 text-body-xs text-foreground">
              {source_reference_label(reference)}
            </code>
          </li>
        </ul>
      </details>
    </section>
    """
  end

  defp source_references(%{source_references: references}) when is_list(references) do
    Enum.filter(references, &source_reference?/1)
  end

  defp source_references(_message), do: []

  defp source_reference?(%{"file" => file}) when is_binary(file), do: true
  defp source_reference?(%{file: file}) when is_binary(file), do: true
  defp source_reference?(_reference), do: false

  defp relation_name(%{name: name}, _fallback) when is_binary(name) and name != "", do: name
  defp relation_name(_relation, fallback), do: fallback

  defp context_label(context) when is_binary(context) and context != "", do: context
  defp context_label(_context), do: "default"

  defp translation_id(%{id: id}) when not is_nil(id), do: id
  defp translation_id(_translation), do: nil

  defp source_reference_label(%{"file" => file, "line" => line}), do: reference_label(file, line)
  defp source_reference_label(%{file: file, line: line}), do: reference_label(file, line)
  defp source_reference_label(reference), do: inspect(reference)

  defp reference_label(file, line) when is_integer(line), do: "#{file}:#{line}"
  defp reference_label(file, line) when is_binary(line) and line != "", do: "#{file}:#{line}"
  defp reference_label(file, _line), do: file
end
