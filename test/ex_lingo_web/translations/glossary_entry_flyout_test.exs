defmodule ExLingoWeb.Translations.Components.GlossaryEntryFlyoutTest do
  use ExUnit.Case, async: true

  alias ExLingo.AI.Translations.Plugin
  alias ExLingoWeb.Translations.Components.GlossaryEntryFlyout

  describe "prefill_attrs/3" do
    test "uses the selected terms and the message's target locale and domain" do
      message = %{msgid: "Cancel", domain_id: 7}
      locale = %{iso639_code: "de"}
      payload = %{"source_term" => "Cancel", "target_term" => "Abbrechen"}

      attrs = GlossaryEntryFlyout.prefill_attrs(message, locale, payload)

      assert attrs["source_locale"] == Plugin.source_locale()
      assert attrs["target_locale"] == "de"
      assert attrs["source_term"] == "Cancel"
      assert attrs["target_term"] == "Abbrechen"
      assert attrs["domain_id"] == 7
    end

    test "falls back to the full msgid when no source term is selected" do
      message = %{msgid: "Cancel order", domain_id: nil}
      locale = %{iso639_code: "de"}

      attrs = GlossaryEntryFlyout.prefill_attrs(message, locale, %{"source_term" => "  "})

      assert attrs["source_term"] == "Cancel order"
      assert attrs["target_term"] == ""
      assert attrs["domain_id"] == nil
    end

    test "treats a whitespace-only target term as empty" do
      message = %{msgid: "Cancel", domain_id: nil}
      locale = %{iso639_code: "de"}

      attrs =
        GlossaryEntryFlyout.prefill_attrs(message, locale, %{
          "source_term" => "Cancel",
          "target_term" => "   "
        })

      assert attrs["target_term"] == ""
    end
  end
end
