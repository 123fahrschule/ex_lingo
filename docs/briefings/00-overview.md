# PO-Feedback — Umsetzungsplan

Sammlung aller Aufgaben aus dem PO-Feedback, jeweils mit einem eigenen Briefing zur Übergabe an Claude Code.

## Reihenfolge (klein → groß)

1. [`01-cleanup-dead-context-dirs.md`](01-cleanup-dead-context-dirs.md) — Tote Ordner löschen (5 Min)
2. [`02-merge-instructions-to-english.md`](02-merge-instructions-to-english.md) — AI-Merge-Anweisungen ins Englische (15 Min)
3. [`03-translation-validations.md`](03-translation-validations.md) — Längen-Farbcoding, Placeholder-Check, Satzende-Check
4. [`04-glossary-from-translation.md`](04-glossary-from-translation.md) — Button im Editor: aus Übersetzung Glossar-Eintrag anlegen
5. [`05-inline-editing-in-list.md`](05-inline-editing-in-list.md) — **PO-Priorität #1**: Flyout und Vollseite raus, Inline-Bearbeitung in der Liste (Vorbild: poeditor.com)
6. [`06-settings-page-and-ai-prompts.md`](06-settings-page-and-ai-prompts.md) — Settings-Bereich + konfigurierbare AI-Prompts (global + pro Locale, kaskadierend)
7. [`07-image-upload-s3.md`](07-image-upload-s3.md) — S3-Bild-Upload als Kontext (hängt an Briefing 06)

## Bereits umgesetzt — nichts zu tun

- **Button "Context unklar" → Devs spiegeln**: Existiert in `lib/ex_lingo_web/live/translations/translation_form_live/components/message_metadata.ex` (Zeile 39–50). Liste unter `/unclear-texts` (`UnclearTextsLive`).
- **Context-Verwaltungsseite entfernt**: Router hat keine `/contexts`-Route mehr. Aber: tote Ordner liegen rum — siehe Briefing 01.

## Briefing-Konventionen

Jedes Briefing enthält:
- **Ziel**: Warum dieses Feature.
- **Was tun**: Konkrete Anweisung.
- **Betroffene Dateien**: Mit Pfaden.
- **Akzeptanzkriterien**: Was "done" bedeutet.
- **Out of Scope**: Was bewusst nicht angefasst wird.
