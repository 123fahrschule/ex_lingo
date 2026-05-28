# 05 — Inline-Editing in der Übersetzungs-Liste (PO-Priorität #1)

## Ziel

Aktuell muss der Übersetzer für jede Message:

1. In der Liste auf eine Zeile klicken
2. Ein Flyout oder eine eigene Seite öffnet sich
3. Übersetzung eintragen, speichern
4. Zurück zur Liste

Das ist der wichtigste Pain-Point des PO. Vorbild ist [poeditor.com](https://poeditor.com/) (Product-Tour ansehen): zwei Spalten, links Source-Text, rechts direkt editierbares Translation-Feld, alles inline in der Tabelle. Speichern beim Blur/Enter.

**Beide alten Pfade müssen weg**: das Flyout (eingebettet in `TranslationsLive` via `?edit_message_id=…`) **und** die separate Seite (`TranslationFormLive` unter `/locales/:locale_id/translations/:message_id`).

## Kontext: Was heute existiert

- **Liste**: `lib/ex_lingo_web/live/translations/translations_live/translations_live.{ex,html.heex}` + `components/messages_table/`.
- **Flyout-Modus**: Wird in `TranslationsLive` mit `assign_editor_from_params/2` (Zeile 366–411) aktiviert, sobald URL `?edit_message_id=…` enthält. Lädt `editing_message`, `editing_translations` etc. und rendert vermutlich in `translations_live.html.heex` ein Side-Panel.
- **Separate Seite**: `lib/ex_lingo_web/live/translations/translation_form_live/translation_form_live.ex`, Router Zeile 64: `live "/:message_id", TranslationFormLive, :show`.
- **Form-Komponenten**: `singular_translation_form/` und `plural_translation_form/` unter `translation_form_live/components/` — diese **bleiben als Komponenten erhalten**, werden aber inline gerendert statt auf eigener Seite/im Flyout.

## Was tun

### 1. Inline-Edit-Modus in `messages_table`

`messages_table.html.heex` umbauen so, dass jede Zeile direkt eingebettete Edit-Inputs zeigt:

**Layout-Vorschlag (zwei Hauptspalten):**

```
| ☐ | Source (msgid + Domain/Context/Type kompakt) | Translation (Input live) | ⚠ Validation badges | Actions (⋯ menu) |
```

- Bei Singular: ein Input pro Zeile.
- Bei Plural: pro Plural-Form ein eigener Input, untereinander in der Zeile gestapelt (kleine Sub-Zeilen). Plural-Form-Beschriftung (z. B. "one", "other") links neben dem Input.
- **Form-Komponenten wiederverwenden**: `SingularTranslationForm` und `PluralTranslationForm` sind heute eigenständige `live_component`s. Sie sollten unverändert (oder minimal angepasst) als Inline-Komponente direkt in die Tabellen-Zelle eingebettet werden.

### 2. Speichern

- **Auto-Save on Blur**: Sobald das Feld den Fokus verliert (`phx-blur`), wird gespeichert.
- **Speichern mit Cmd/Ctrl+Enter**: Wie poeditor — explizites Speichern + zur nächsten Zeile springen.
- **Save-State pro Zeile sichtbar**: Kleines Icon (Spinner während Save, Häkchen bei Erfolg, rot bei Fehler — 1–2 Sekunden Anzeigedauer, dann zurück zu neutral).
- **Optimistisches Update**: UI zeigt sofort den neuen Wert, Rollback bei Server-Fehler.

### 3. AI-Suggestion + Glossar-Button inline

Die "AI Suggestion"-Aktion und "Add to glossary" (Briefing 04) müssen pro Zeile direkt erreichbar sein. Vorschlag: ein kleines `⋯`-Dropdown am Zeilen-Ende, mit:

- Get AI suggestion
- Add to glossary
- Mark context as unclear (existiert heute im Flyout — siehe `message_metadata.ex` Zeile 39–50)
- Show source positions
- Show possible duplicates (falls welche existieren)

### 4. Filter-/Such-Bar bleibt oben

Die heutige `FiltersBar` ist gut. Nicht anrühren außer ggf. um eine "Zeige nur fehlende Übersetzungen"-Toggle prominenter zu machen (existiert bereits als `not_translated`-Filter).

### 5. Alte Pfade entfernen

- Router (`lib/ex_lingo_web/router.ex`): Zeile 64 (`live "/:message_id", TranslationFormLive, :show, route_opts`) entfernen.
- Datei `lib/ex_lingo_web/live/translations/translation_form_live/translation_form_live.ex` löschen — Komponenten unter `translation_form_live/components/` bleiben (werden inline gerendert).
- Aus `TranslationsLive`: `assign_editor_defaults/1`, `assign_editor_from_params/2` und der Flyout-Render-Block raus. Auch `handle_event("edit_message", …)` und `handle_event("close_translation", …)` entfernen oder umbiegen.
- `edit_message_id` und `tab` aus den URL-Parametern entfernen. `TranslationEditorLoader` (`lib/ex_lingo_web/live/translations/translation_editor_loader.ex`) prüfen, ob Logik fürs Laden mehrerer Translations pro Message wiederverwendet werden kann — wahrscheinlich ja, dann in den neuen Inline-Workflow integrieren.

### 6. AI-Suggestion-Integration anpassen

Heute kommt `:ai_suggestion_accepted`-Nachricht zurück und stellt das Editor-Setup wieder her. Im Inline-Modus: AI-Suggestion ruft pro Zeile, Antwort landet als Vorschlag-Bubble unter dem Input mit "Accept" / "Reject"-Buttons (oder einfach in den Input vorschlagen mit Möglichkeit, ihn wieder rückgängig zu machen).

### 7. Possible-Duplicates-Hinweis

Heute werden `possible_duplicate_summaries` im Editor angezeigt. Inline: kleines Badge in der Zeile (z. B. "2 possible duplicates"), Klick öffnet ein Pop-Over mit Details — oder linkt zur `/possible-duplicates`-Seite mit Vorfilter.

### 8. Highlight nach Save

Wenn der Übersetzer eine Zeile speichert, soll sie kurz farblich hinterlegt sein (Highlight-Animation). Heute existiert `highlighted_message_id` — Logik kann übernommen werden, nur als kurze CSS-Animation statt persistent.

## Detailpunkte

- **Pagination und Sort** unverändert lassen (`page`, `page_size`, `sort` in URL bleiben).
- **`list_context_storage_key`** (LocalStorage für Filter-Wiederherstellung) bleibt — `edit_message_id` wird einfach aus dem Payload entfernt.
- **Tab-Index für Tastatur-Navigation**: Übersetzer wollen schnell durchklicken. Jeder Input bekommt eine sinnvolle Tab-Order; nach Cmd/Ctrl+Enter Fokus auf nächsten Input.
- **Plural-Forms** sauber gestaffelt: bei sehr vielen Plural-Formen (Arabisch, Slowakisch) kann eine Zeile mehrere Sub-Zeilen haben. Höhe variabel.
- **Rendering-Performance**: 100 Messages pro Seite mit je 1–6 Inputs heißt potentiell 100–600 LiveComponents. Mit `temporary_assigns` und `phx-update="stream"` arbeiten. Bei Bedarf Seitengröße standardmäßig kleiner (z. B. 50).

## Betroffene Dateien

- `lib/ex_lingo_web/live/translations/translations_live/translations_live.{ex,html.heex}` — Hauptumbau
- `lib/ex_lingo_web/live/translations/translations_live/components/messages_table/messages_table.{ex,html.heex}` — Inline-Inputs
- `lib/ex_lingo_web/live/translations/translation_form_live/translation_form_live.ex` — **löschen**
- `lib/ex_lingo_web/live/translations/translation_form_live/components/*` — **bleiben**, ggf. minimal angepasst für Inline-Kontext
- `lib/ex_lingo_web/live/translations/translation_editor_loader.ex` — prüfen ob noch nötig oder umbauen
- `lib/ex_lingo_web/router.ex` — Route `live "/:message_id", TranslationFormLive` entfernen
- `assets/js/app.js` und ggf. neue Hooks (Tastatur-Navigation, Auto-Save-Trigger)
- Tests: `test/ex_lingo_web/live/translations/translations_live_test.exs` umfangreich anpassen, `translation_form_live_test.exs` ggf. löschen

## Akzeptanzkriterien

- Keine Vollseite mehr, kein Flyout mehr.
- In der Liste lässt sich jede Übersetzung direkt in der Zeile bearbeiten (Singular und Plural).
- Auto-Save on Blur funktioniert; Cmd/Ctrl+Enter speichert und springt zur nächsten Zeile.
- Save-Status (Spinner/Häkchen/Fehler) ist pro Zeile sichtbar.
- Validierungen aus Briefing 03 funktionieren weiterhin (Border-Color, Hinweise).
- AI-Suggestion, "Add to glossary", "Mark context unclear" pro Zeile erreichbar.
- Filter, Sortierung, Pagination, "Zeige nur fehlende" weiterhin funktional.
- Router-Route `/locales/:locale_id/translations/:message_id` ist weg, gibt `404` oder Redirect.
- `mix test` grün, `mix compile --warnings-as-errors` clean.
- Manueller Smoke-Test: 5–10 Übersetzungen schnell hintereinander bearbeiten ist messbar schneller als vorher.

## Out of Scope

- Re-Design der Filter-Bar.
- Neue AI-Provider.
- Image-Upload (Briefing 07) und Settings-Page (Briefing 06).
- Bulk-Edit über Checkboxen (gerne später).

## Risiko / Hinweis

Das ist das größte der sieben Briefings. Realistisch: 2–4 Implementierungs-Sessions mit Claude Code. Empfehlung: zuerst nur Singular inline lauffähig kriegen, dann Plural, dann AI-Suggestion + Validierungen anbinden, dann alte Pfade entfernen. Nicht alles in einem Durchgang.
