defmodule ExLingoWeb.Translations.GlossaryEntriesTableTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ExLingo.Translations.GlossaryEntry
  alias ExLingoWeb.Translations.GlossaryEntriesTable

  test "renders glossary entries" do
    html =
      render_component(&GlossaryEntriesTable.render/1,
        id: "glossary-table",
        myself: nil,
        glossary_entries: [
          %GlossaryEntry{
            id: 1,
            source_locale: "en",
            target_locale: "de",
            source_term: "Certificate",
            target_term: "Ausbildungsnachweis"
          }
        ]
      )

    assert html =~ "Certificate"
    assert html =~ "Ausbildungsnachweis"
    assert html =~ "en"
    assert html =~ "de"
  end
end
