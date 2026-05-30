defmodule ExLingo.PoFiles.POExporterTest do
  use ExLingo.Test.DataCase, async: false

  alias ExLingo.PoFiles.POExporter
  alias ExLingo.Translations

  setup do
    ExLingo.Cache.delete_all()

    {:ok, locale} =
      Translations.create_locale(%{iso639_code: "de", name: "German", native_name: "Deutsch"})

    %{locale: locale}
  end

  defp singular(locale, msgid, translated, attrs \\ %{}) do
    {:ok, message} =
      Translations.create_message(Map.merge(%{msgid: msgid, message_type: :singular}, attrs))

    {:ok, _} =
      Translations.create_singular_translation(%{
        message_id: message.id,
        locale_id: locale.id,
        original_text: msgid,
        translated_text: translated
      })

    message
  end

  defp file_for(files, suffix) do
    Enum.find(files, fn %{path: path} -> String.ends_with?(path, suffix) end)
  end

  test "exports singular translations into a per-locale/domain po file", %{locale: locale} do
    singular(locale, "Save", "Speichern")

    files = POExporter.export_files()
    file = file_for(files, "de/LC_MESSAGES/default.po")

    assert file
    assert file.content =~ ~s(msgid "Save")
    assert file.content =~ ~s(msgstr "Speichern")
  end

  test "renders msgctxt only for non-default context", %{locale: locale} do
    singular(locale, "Open", "Öffnen", %{context: "button"})
    singular(locale, "Close", "Schließen", %{context: "default"})

    content =
      POExporter.export_files() |> file_for("de/LC_MESSAGES/default.po") |> Map.fetch!(:content)

    assert content =~ ~s(msgctxt "button")
    refute content =~ ~s(msgctxt "default")
  end

  defp plural(locale, msgid, forms, attrs \\ %{}) do
    {:ok, message} =
      Translations.create_message(Map.merge(%{msgid: msgid, message_type: :plural}, attrs))

    for {index, text} <- forms do
      {:ok, _} =
        Translations.create_plural_translation(%{
          message_id: message.id,
          locale_id: locale.id,
          nplural_index: index,
          original_text: text,
          translated_text: text
        })
    end

    message
  end

  test "exports plural translations with the stored source plural form", %{locale: locale} do
    plural(locale, "apple", [{0, "Apfel"}, {1, "Äpfel"}], %{msgid_plural: "apples"})

    content =
      POExporter.export_files() |> file_for("de/LC_MESSAGES/default.po") |> Map.fetch!(:content)

    assert content =~ ~s(msgid "apple")
    assert content =~ ~s(msgid_plural "apples")
    assert content =~ ~s(msgstr[0] "Apfel")
    assert content =~ ~s(msgstr[1] "Äpfel")
  end

  test "fills gaps in plural indices so msgstr stays contiguous", %{locale: locale} do
    # Indices 0 and 2 present, 1 missing — output must still include msgstr[1].
    plural(locale, "file", [{0, "Datei"}, {2, "Dateien"}], %{msgid_plural: "files"})

    content =
      POExporter.export_files() |> file_for("de/LC_MESSAGES/default.po") |> Map.fetch!(:content)

    assert content =~ ~s(msgstr[0] "Datei")
    assert content =~ ~s(msgstr[1] "")
    assert content =~ ~s(msgstr[2] "Dateien")
  end

  test "falls back to msgid when no source plural form was stored", %{locale: locale} do
    plural(locale, "car", [{0, "Auto"}, {1, "Autos"}])

    content =
      POExporter.export_files() |> file_for("de/LC_MESSAGES/default.po") |> Map.fetch!(:content)

    assert content =~ ~s(msgid "car")
    assert content =~ ~s(msgid_plural "car")
  end

  test "groups messages by domain into separate files", %{locale: locale} do
    {:ok, domain} = Translations.create_domain(%{name: "errors"})
    singular(locale, "Not found", "Nicht gefunden", %{domain_id: domain.id})

    files = POExporter.export_files()

    assert file_for(files, "de/LC_MESSAGES/errors.po")
  end

  test "export_zip returns a zip archive", %{locale: locale} do
    singular(locale, "Save", "Speichern")

    assert {:ok, binary} = POExporter.export_zip()
    assert <<"PK", _rest::binary>> = binary
  end
end
