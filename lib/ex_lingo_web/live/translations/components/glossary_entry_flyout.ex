defmodule ExLingoWeb.Translations.Components.GlossaryEntryFlyout do
  @moduledoc """
  Shared right-side flyout for creating or updating a glossary entry.

  Used both by the glossary section and by the quick-capture action in the
  translation editor, so they open the same flyout instead of a standalone page.

  The host LiveView drives it through these events, which carry no `phx-target`
  and therefore reach the LiveView itself: `close_glossary_entry_editor`,
  `validate_glossary_entry`, and `submit_glossary_entry`. The flyout renders only
  when `form` is set.
  """
  use ExLingoWeb, :component

  alias ExLingo.AI.Translations.Plugin

  attr :form, :any, default: nil
  attr :editing?, :boolean, default: false
  attr :domains, :list, default: []

  def glossary_entry_flyout(assigns) do
    ~H"""
    <.sheet
      :if={@form}
      id="glossary-entry-editor-sheet"
      open={true}
      on-close="close_glossary_entry_editor"
    >
      <.sheet_content side="right" size="lg" class="w-full overflow-hidden">
        <.sheet_header class="pr-8">
          <.sheet_title class="text-h3">
            <%= if @editing?, do: t("Update glossary entry"), else: t("Create glossary entry") %>
          </.sheet_title>
          <.sheet_description>
            {t("Define approved terminology for one language direction.")}
          </.sheet_description>
        </.sheet_header>

        <div class="mt-4 flex-1 overflow-y-auto pr-1">
          <.form
            for={@form}
            phx-change="validate_glossary_entry"
            phx-submit="submit_glossary_entry"
            class="space-y-5"
          >
            <div class="grid gap-4 md:grid-cols-2">
              <.form_item>
                <.form_label field={@form[:source_locale]}>{t("Source locale")}</.form_label>
                <.form_control>
                  <.input field={@form[:source_locale]} type="text" placeholder="en" />
                </.form_control>
                <.form_message field={@form[:source_locale]} translate={false} />
              </.form_item>

              <.form_item>
                <.form_label field={@form[:target_locale]}>{t("Target locale")}</.form_label>
                <.form_control>
                  <.input field={@form[:target_locale]} type="text" placeholder="de" />
                </.form_control>
                <.form_message field={@form[:target_locale]} translate={false} />
              </.form_item>
            </div>

            <.form_item>
              <.form_label field={@form[:source_term]}>{t("Source term")}</.form_label>
              <.form_control>
                <.input field={@form[:source_term]} type="text" />
              </.form_control>
              <.form_message field={@form[:source_term]} translate={false} />
            </.form_item>

            <.form_item>
              <.form_label field={@form[:target_term]}>{t("Target term")}</.form_label>
              <.form_control>
                <.input field={@form[:target_term]} type="text" />
              </.form_control>
              <.form_message field={@form[:target_term]} translate={false} />
            </.form_item>

            <.form_item>
              <.form_label field={@form[:usage_guidance]}>{t("Usage guidance")}</.form_label>
              <.form_control>
                <.textarea field={@form[:usage_guidance]} rows="3" />
              </.form_control>
              <.form_message field={@form[:usage_guidance]} translate={false} />
            </.form_item>

            <% select_class =
              "flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-body-sm shadow-sm focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50" %>

            <div class="grid gap-4 md:grid-cols-2">
              <.form_item>
                <.form_label field={@form[:domain_id]}>{t("Domain scope")}</.form_label>
                <.form_control>
                  <select
                    id={@form[:domain_id].id}
                    name={@form[:domain_id].name}
                    class={select_class}
                  >
                    <option value="">{t("Global")}</option>
                    <option
                      :for={domain <- @domains}
                      value={domain.id}
                      selected={to_string(domain.id) == to_string(@form[:domain_id].value)}
                    >
                      {domain.name}
                    </option>
                  </select>
                </.form_control>
                <.form_message field={@form[:domain_id]} translate={false} />
              </.form_item>
            </div>

            <.sheet_footer class="pt-4">
              <.button type="submit" phx-disable-with={t("Saving...")}>
                <.icon name="save" size="sm" decorative /> {t("Save")}
              </.button>
            </.sheet_footer>
          </.form>
        </div>
      </.sheet_content>
    </.sheet>
    """
  end

  @doc """
  Builds the prefilled glossary-entry attributes for the quick-capture flow from
  the translation editor. `payload` is the client selection event
  (`%{"source_term" => _, "target_term" => _}`); an empty source term falls back
  to the full `msgid`, the target term stays empty.
  """
  @spec prefill_attrs(map, map, map) :: map
  def prefill_attrs(message, locale, payload)
      when is_map(message) and is_map(locale) and is_map(payload) do
    msgid = Map.get(message, :msgid) || ""

    %{
      "source_locale" => Plugin.source_locale(),
      "target_locale" => Map.get(locale, :iso639_code) || "",
      "source_term" => fallback(Map.get(payload, "source_term"), msgid),
      "target_term" => fallback(Map.get(payload, "target_term"), ""),
      "domain_id" => Map.get(message, :domain_id)
    }
  end

  defp fallback(nil, fallback), do: fallback
  defp fallback("", fallback), do: fallback

  defp fallback(value, fallback) when is_binary(value) do
    case String.trim(value) do
      "" -> fallback
      trimmed -> trimmed
    end
  end

  defp fallback(_value, fallback), do: fallback
end
