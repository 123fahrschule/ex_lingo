# 02 — AI-Merge-Anweisungen ins Englische

## Ziel

Auf `/possible-duplicates` gibt es pro Kandidaten-Gruppe einen Button "Copy AI instructions". Beim Klick wird ein vorgefertigter Prompt in die Zwischenablage kopiert, mit dem Entwickler in ihrem Code-Editor (Claude Code, Cursor) die Key-Zusammenführung im Anwendungs-Repo durchführen. Aktuell ist dieser Prompt-Text auf Deutsch — die meisten Entwickler sprechen aber kein Deutsch.

**Funktionalität bleibt 1:1, nur der erzeugte Text wird ins Englische übersetzt.**

## Was tun

In `lib/ex_lingo_web/live/translations/components/possible_duplicate_components.ex` die Funktion `ai_cleanup_instruction/1` (ab Zeile 194) sowie ihre Helper ins Englische übersetzen:

1. **`ai_cleanup_instruction/1`** (Zeile 194 ff.) — der Hauptprompt. Englische Übersetzung soll inhaltlich exakt entsprechen, in idiomatischem Englisch. Beispiel-Anfang:

   > You are working in the repository of the application where these UI texts are used. Please review this possible duplicate translation in the application code and only consolidate it if the semantics are truly identical.
   >
   > Important:
   > - First check the source positions listed below in the application code. If a source position is missing, search for the given source text.
   > - Only merge keys when meaning, usage context, placeholders, plural form, grammar and likelihood of future divergence are fully identical.
   > - Identical target translations alone are not enough. If a text could be understood differently depending on the UI location, keep them separate.
   > - When merging, update the application code so that the affected places use the same semantically appropriate i18n/gettext key. Then remove unused duplicate keys/entries if the project has a clear mechanism for that.
   > - Keep the patch small, do not change unrelated translations, and run the relevant tests.

   Labels in den darunter aufgelisteten Detailblöcken ebenfalls übersetzen: "Typ" → "Type", "Sicherheit" → "Confidence", "Grund" → "Reason", "Aktuelle Übersetzung" → "Current translation", "Pluralform" → "Plural form", "Quelltexte / Suchbegriffe" → "Source texts / search terms", "Zu prüfende Stellen" → "Locations to review".

2. **`plural_instruction_line/1`** (Zeile 238) — `"- Pluralform: …"` → `"- Plural form: …"`.

3. **`formatted_app_occurrences/1`** (Zeile 250 ff.) — die Felder:
   - "Quellpositionen" → "Source positions"
   - "Quelltext / Suchbegriff" → "Source text / search term"
   - "Aktuelle Übersetzung" → "Current translation"
   - "Typ" → "Type"

4. **`formatted_instruction_source_references/1`** (Zeile 281, 284) — `"nicht aufgezeichnet; suche nach dem Quelltext / Suchbegriff"` → `"not recorded; search by source text / search term"`.

## Wichtig

- Der Text wird im Browser per Clipboard kopiert und in einen externen Code-Editor eingefügt. Er ist **nicht** über `t(…)` (Gettext) lokalisiert — und das soll auch so bleiben. Englisch ist die fest verdrahtete Zielsprache, weil das Zielpublikum Entwickler sind.
- Funktionen `translation_type_label/1`, `confidence_label/1`, `reason_label/1`, `occurrence_type_label/1` rufen `t(…)` auf und liefern lokalisierte Strings für die UI — diese hier **nicht** anrühren. Die Englisch-Anforderung gilt nur für den Clipboard-Text. Falls Mischsprache stört: in `ai_cleanup_instruction/1` durch englische String-Literale ersetzen (z. B. `translation_type_label/1` inline mit fester englischer Variante aufrufen oder eine zweite Helper-Funktion `english_translation_type_label/1` bauen).

## Betroffene Dateien

- `lib/ex_lingo_web/live/translations/components/possible_duplicate_components.ex` (Zeile 194–288)
- ggf. Test-Datei: `test/ex_lingo_web/live/translations/components/possible_duplicate_components_test.exs` (falls vorhanden — sonst überspringen)

## Akzeptanzkriterien

- Der per "Copy AI instructions"-Button erzeugte Text ist vollständig auf Englisch (kein deutsches Wort mehr).
- Inhaltlich entspricht er dem bisherigen deutschen Text.
- UI-Texte auf der `/possible-duplicates`-Seite selbst (Button-Label, Tooltip, Header) bleiben unverändert und weiterhin per `t(…)` lokalisiert.
- Tests grün, keine Compile-Warnings.

## Out of Scope

- Logik der Duplikat-Erkennung.
- UI-Komponenten auf `/possible-duplicates` außer dem Clipboard-Inhalt.
- Lokalisierung der App-UI (das ist eine separate Sache).
