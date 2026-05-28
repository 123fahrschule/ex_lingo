# 04 — Glossar-Eintrag direkt aus einer Übersetzung erzeugen

## Ziel

Heute existiert `/glossary` mit voller CRUD-Funktionalität. Beim Übersetzen einer Message merkt der PO regelmäßig: "Dieser Begriff sollte ins Glossar". Aktuell muss er dazu die Seite wechseln, manuell Source-/Target-Locale wählen, Begriffe abtippen.

Wunsch: Ein Button im Übersetzungs-Editor, der einen neuen Glossar-Eintrag mit vorausgefüllten Feldern startet.

## Was tun

### UI-Button im Translation-Editor

**Wichtig:** Briefing 05 baut den Editor von Vollseite/Flyout zu Inline um. Diesen Button so platzieren, dass er beim Inline-Umbau einfach mitgeht — ideal direkt neben den Übersetzungs-Inputs oder im Metadaten-Block der Message (`message_metadata.ex`).

Button-Label: "Add to glossary" (lokalisierbar). Icon: book/library.

### Vorausfüllung

Klick öffnet `GlossaryEntryFormLive` (existiert bereits unter `lib/ex_lingo_web/live/translations/glossary_entry_form_live/`) mit Query-Parametern oder Session-State, der folgendes vorausfüllt:

- `source_locale`: Source-Locale des Projekts (steckt heute in der Plugin-Config `ExLingo.AI.Translations.Plugin` als `source_locale`)
- `target_locale`: Die aktuell bearbeitete Locale
- `source_term`: **Auswahl** des Übersetzers im Source-Text. Wenn keine Auswahl: ganzer msgid als Default (kann der User dann kürzen).
- `target_term`: Auswahl im Target-Input. Wenn leer: leer lassen.
- `domain_id`: Die Domain der Message (falls vorhanden).
- `application_source_id`: Die Application-Source der Message (falls vorhanden).
- `usage_guidance`: leer.

### Mechanismus für Text-Auswahl

In den Translation-Form-HTML-Templates Hook hinzufügen: bei Klick auf den "Add to glossary"-Button die aktuelle `window.getSelection()` aus dem Source-Anzeige-Block und dem Target-Input abgreifen. Phoenix-JS-Hook (`phx-hook`):

```javascript
{
  mounted() {
    this.el.addEventListener("click", (e) => {
      const sourceSel = document.querySelector("[data-glossary-source]")?.textContent;
      const sourceMarked = window.getSelection().toString();
      const targetInput = document.querySelector("[data-glossary-target]");
      const targetMarked = targetInput
        ? targetInput.value.substring(targetInput.selectionStart, targetInput.selectionEnd)
        : "";
      this.pushEvent("open_glossary_for_selection", {
        source_term: sourceMarked || sourceSel,
        target_term: targetMarked
      });
    });
  }
}
```

Server-Handler: `handle_event("open_glossary_for_selection", params, socket)` → `push_navigate` zu `/glossary/new?...` mit den Werten als Query-Params.

### `GlossaryEntryFormLive` erweitern

`mount/3` muss die zusätzlichen Query-Params lesen und in das initiale Changeset einsetzen. Datei: `lib/ex_lingo_web/live/translations/glossary_entry_form_live/glossary_entry_form_live.ex`.

Nach erfolgreichem Speichern: Rück-Navigation zurück zur Übersetzungs-Liste mit der vorher bearbeiteten Message ausgewählt. Heute geht `GlossaryEntryFormLive` zurück nach `/glossary`. Hier muss eine Option für "Return URL" hinzu, die per Query-Param `return_to=` übergeben werden kann (mit Whitelist-Check, dass die URL eine Dashboard-Route ist, siehe `safe_dashboard_path/2` in `translations_live.ex`).

## Betroffene Dateien

- `lib/ex_lingo_web/live/translations/translation_form_live/components/message_metadata.ex` — Button hinzufügen
- `lib/ex_lingo_web/live/translations/translation_form_live/components/singular_translation_form/singular_translation_form.{ex,html.heex}` — Selection-Hook und Event-Handler
- `lib/ex_lingo_web/live/translations/translation_form_live/components/plural_translation_form/plural_translation_form.{ex,html.heex}` — analog für Plural
- `lib/ex_lingo_web/live/translations/glossary_entry_form_live/glossary_entry_form_live.ex` — Query-Params auswerten, `return_to` unterstützen
- `assets/js/hooks/` (neu oder bestehend) — JS-Hook für Selection
- `assets/js/app.js` — Hook registrieren
- Tests anlegen / anpassen

## Akzeptanzkriterien

- Im Translation-Editor sichtbarer Button "Add to glossary".
- Klick öffnet das Glossar-Formular mit vorausgefüllten Werten (Source-/Target-Locale, Domain, Application-Source aus der Message; ausgewählter Text als Begriff oder ganzer msgid als Fallback).
- Speichern führt zurück zur Übersetzungs-Liste mit derselben Message aktiv.
- Abbrechen führt ebenfalls zurück.
- Tests grün.

## Out of Scope

- AI-Vorschlag für Glossar-Einträge (z. B. "Welche Begriffe sind glossarwürdig?").
- Bulk-Import von Glossar-Einträgen.
- Glossar-Eintrag direkt inline anlegen ohne Seitenwechsel (kommt später, wenn nötig — erstmal soll Form-Reuse genutzt werden).
