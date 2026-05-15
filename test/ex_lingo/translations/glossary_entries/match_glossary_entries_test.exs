defmodule ExLingo.Translations.GlossaryEntries.MatchGlossaryEntriesTest do
  use ExLingo.Test.DataCase, async: false

  alias ExLingo.Translations
  alias ExLingo.Translations.GlossaryEntries.Services.MatchGlossaryEntries

  setup do
    suffix = System.unique_integer([:positive])

    {:ok, domain} = Translations.create_domain(%{name: "training_#{suffix}"})
    {:ok, other_domain} = Translations.create_domain(%{name: "billing_#{suffix}"})
    {:ok, context} = Translations.create_context(%{name: "context_#{suffix}"})
    {:ok, application_source} = Translations.create_application_source(%{name: "admin_#{suffix}"})

    {:ok, message} =
      Translations.create_message(%{
        msgid: "Download certificate",
        message_type: :singular,
        domain_id: domain.id,
        context_id: context.id,
        application_source_id: application_source.id
      })

    %{
      domain: domain,
      other_domain: other_domain,
      message: message
    }
  end

  test "matches by language direction and source term", %{message: message} do
    {:ok, matching} =
      Translations.create_glossary_entry(%{
        source_locale: "en",
        target_locale: "de",
        source_term: "Certificate",
        target_term: "Ausbildungsnachweis"
      })

    {:ok, _wrong_target} =
      Translations.create_glossary_entry(%{
        source_locale: "en",
        target_locale: "hu",
        source_term: "Certificate",
        target_term: "Tanúsítvány"
      })

    {:ok, _missing_term} =
      Translations.create_glossary_entry(%{
        source_locale: "en",
        target_locale: "de",
        source_term: "Invoice",
        target_term: "Rechnung"
      })

    result =
      MatchGlossaryEntries.call(%{
        source_locale: "en",
        target_locale: "de",
        source_text: message.msgid,
        message: message
      })

    assert Enum.map(result, & &1.id) == [matching.id]
  end

  test "excludes scoped entries that do not match the message", %{
    message: message,
    other_domain: other_domain
  } do
    {:ok, _wrong_scope} =
      Translations.create_glossary_entry(%{
        source_locale: "en",
        target_locale: "de",
        source_term: "Certificate",
        target_term: "Bescheinigung",
        domain_id: other_domain.id
      })

    result =
      MatchGlossaryEntries.call(%{
        source_locale: "en",
        target_locale: "de",
        source_text: message.msgid,
        message: message
      })

    assert result == []
  end

  test "orders scoped entries before global entries", %{message: message, domain: domain} do
    {:ok, global} =
      Translations.create_glossary_entry(%{
        source_locale: "en",
        target_locale: "de",
        source_term: "Certificate",
        target_term: "Ausbildungsbescheinigung"
      })

    {:ok, scoped} =
      Translations.create_glossary_entry(%{
        source_locale: "en",
        target_locale: "de",
        source_term: "Certificate",
        target_term: "Ausbildungsnachweis",
        domain_id: domain.id
      })

    result =
      MatchGlossaryEntries.call(%{
        source_locale: "en",
        target_locale: "de",
        source_text: message.msgid,
        message: message
      })

    assert Enum.map(result, & &1.id) == [scoped.id, global.id]
  end

  test "matches global entries when optional message scopes are nil" do
    {:ok, message} =
      Translations.create_message(%{
        msgid: "Download certificate",
        message_type: :singular
      })

    {:ok, matching} =
      Translations.create_glossary_entry(%{
        source_locale: "en",
        target_locale: "de",
        source_term: "Certificate",
        target_term: "Ausbildungsnachweis"
      })

    result =
      MatchGlossaryEntries.call(%{
        source_locale: "en",
        target_locale: "de",
        source_text: message.msgid,
        message: message
      })

    assert Enum.map(result, & &1.id) == [matching.id]
  end
end
