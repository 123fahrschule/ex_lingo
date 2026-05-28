defmodule ExLingoWeb.Translations.PossibleDuplicatesLiveTest do
  use ExLingo.Test.DataCase, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias ExLingo.Translations
  alias ExLingoWeb.Translations.PossibleDuplicatesLive

  @endpoint ExLingo.Test.Endpoint

  setup do
    ExLingo.Cache.delete_all()

    {:ok, locale} =
      Translations.create_locale(%{
        iso639_code: "de",
        name: "German",
        native_name: "Deutsch"
      })

    {:ok, domain} = Translations.create_domain(%{name: "default"})

    create_singular(locale, domain, "modal", "Cancel", "Abbrechen")
    create_singular(locale, domain, "form", "Cancel", "Abbrechen")

    %{locale: locale}
  end

  test "renders possible duplicate groups for the selected locale", %{locale: locale} do
    {:ok, _view, html} =
      build_conn()
      |> live_isolated(PossibleDuplicatesLive, session: %{})

    assert html =~ "Possible duplicates"
    assert html =~ locale.native_name
    assert html =~ "Abbrechen"
    assert html =~ "Same source and translation"
  end

  defp create_singular(locale, domain, context, msgid, translated_text) do
    {:ok, message} =
      Translations.create_message(%{
        msgid: msgid,
        message_type: :singular,
        domain_id: domain.id,
        context: context
      })

    {:ok, _translation} =
      Translations.create_singular_translation(%{
        message_id: message.id,
        locale_id: locale.id,
        original_text: msgid,
        translated_text: translated_text
      })

    message
  end
end
