# 03 — Übersetzungs-Validierungen: Länge, Placeholder, Satzende

## Ziel

Übersetzer fehlen heute drei einfache, aber wirksame Sicherheitsnetze:

1. **Längen-Warnung mit Farbcoding** — Übersetzungen, die deutlich länger als das Original sind, brechen UI-Layouts. Vorbild: PO-Editor (poeditor.com) markiert Längendifferenz farblich.
2. **Placeholder-Check** — Gettext-Platzhalter wie `%{name}` müssen 1:1 in der Übersetzung enthalten sein, sonst Runtime-Fehler.
3. **Satzende-Check** — Endet das Original mit einem Satzzeichen (`. ! ?`), sollte die Übersetzung dasselbe Zeichen am Ende haben.

Alle drei sind **Warnungen, keine harten Blocker**. Übersetzer kann trotzdem speichern, sieht aber visuell, dass etwas nicht stimmt.

## Was tun

### Datenmodell: nichts

Validierungen sind reine UI-/Logik-Layer-Sache. Kein Migration nötig.

### Validierungs-Modul

Neues Modul `lib/ex_lingo/translations/validations.ex` mit reinen Funktionen:

```elixir
defmodule ExLingo.Translations.Validations do
  @placeholder_regex ~r/%\{[^}]+\}|%[sd]/
  @sentence_endings ["."]
  # offen ob "!" und "?" auch — siehe Akzeptanzkriterien

  def length_status(source, target) when is_binary(source) and is_binary(target) do
    # Liefert: :ok | :slightly_long | :too_long
    # Schwellen: < 1.3× → :ok, < 1.8× → :slightly_long, sonst :too_long
    # Bei sehr kurzen Originalen (< 10 Zeichen) gilt absolute Differenz:
    #   diff <= 5 → :ok, diff <= 15 → :slightly_long, sonst :too_long
  end

  def missing_placeholders(source, target) do
    # Liefert Liste der Platzhalter, die im Source vorkommen, aber nicht im Target.
  end

  def sentence_ending_mismatch?(source, target) do
    # true, wenn Source mit . ! ? endet und Target nicht mit demselben Zeichen.
    # false bei leerem Target.
  end
end
```

Schwellen oben sind **Vorschlag** — siehe Akzeptanzkriterien (Andreas hat poeditor.com als Referenz genannt, aber keine exakten Zahlen — Test mit realistischen 123fs-Strings).

### Integration in UI

**Wichtig:** Briefing 05 (Inline-Editing) ersetzt das aktuelle Translation-Form. Wenn Briefing 03 **vor** Briefing 05 implementiert wird, dann die Validierung in den heutigen Singular-/Plural-Forms unter `lib/ex_lingo_web/live/translations/translation_form_live/components/` einbauen — sie wird später beim Inline-Umbau mitwandern. Wenn **nach** 05: direkt in der Inline-Zelle.

Pro Validierung in der UI:

- **Längen-Status**: Border-Color am Textarea/Input. `:ok` neutral, `:slightly_long` gelb (z. B. `border-amber-400`), `:too_long` rot (`border-red-500`). Daneben kleiner Hinweis: "X Zeichen, Y% länger als Original".
- **Fehlende Placeholder**: Roter Hinweis unter dem Feld: "Missing placeholder(s): `%{name}`, `%{count}`". Solange welche fehlen, Speichern-Button optisch warnen (aber nicht disablen).
- **Satzende-Mismatch**: Gelber Hinweis: "Original ends with '.', translation does not."

Alle Hinweise per `t(…)` lokalisierbar.

### Tests

`test/ex_lingo/translations/validations_test.exs` mit Tabellen-Tests für jede der drei Funktionen. Mindestens je 4–5 Fälle (inkl. Edge-Cases: leer, sehr kurz, Plural, mehrere Placeholder).

## Betroffene Dateien

- `lib/ex_lingo/translations/validations.ex` (neu)
- `lib/ex_lingo_web/live/translations/translation_form_live/components/singular_translation_form/singular_translation_form.{ex,html.heex}`
- `lib/ex_lingo_web/live/translations/translation_form_live/components/plural_translation_form/plural_translation_form.{ex,html.heex}`
- `test/ex_lingo/translations/validations_test.exs` (neu)

## Akzeptanzkriterien

- `Validations.length_status/2`, `missing_placeholders/2`, `sentence_ending_mismatch?/2` existieren und sind getestet.
- Im Translation-Editor:
  - Border-Farbe des Übersetzungs-Inputs ändert sich live (`phx-change`-Hook oder JS-Hook) basierend auf Längen-Status.
  - Fehlende Placeholder werden unter dem Feld gelistet.
  - Satzende-Mismatch wird als kleiner Hinweis angezeigt.
- Speichern bleibt immer möglich (nur Warnung, kein Block).
- Tests grün, `mix dialyzer` ohne neue Warnings.

## Offene Fragen / Entscheidungen für Code

- **Genaue Längen-Schwellen**: 1.3×/1.8× ist ein Vorschlag. Falls poeditor.com andere Zahlen verwendet (Recherche im Code Editor möglich), gerne anpassen. Faustregel: für 123fs-typische Strings (Driving-School-Domain, eher mittelkurz) sind die obigen Werte sinnvoll.
- **Satzende-Set**: Mindestens `.`. Ob `!` und `?` auch eingeschlossen werden sollen — falls UI-Sätze diese Zeichen kaum verwenden, kann es bei nur `.` bleiben. Default: alle drei.
- **Performance**: Validierungen laufen in der UI live bei jedem Tastendruck. Bei langen Texten muss das schnell bleiben — keine RegEx-Backtracking-Fallen.

## Out of Scope

- HTML-Tag-Validierung (z. B. `<strong>` muss in Übersetzung auch da sein) — gerne später als 4. Validierung.
- Server-Side-Validierung beim Speichern (Datenbank-Constraints) — heute auch nicht da, Andreas will reine UI-Warnungen.
- AI-gestützte Qualitätsprüfung.
