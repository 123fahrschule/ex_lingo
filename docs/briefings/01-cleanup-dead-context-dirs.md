# 01 — Tote Context-Ordner aufräumen

## Ziel

Frühere Aufräumung mit Codex hat die `/contexts`-Routes und das Frontend entfernt, aber leere Verzeichnisse stehen geblieben. Code-Hygiene.

## Was tun

Die folgenden Verzeichnisse komplett löschen (inkl. ihrer leeren `components/`-Unterordner):

- `lib/ex_lingo_web/live/translations/contexts_live/`
- `lib/ex_lingo_web/live/translations/context_live/`

Beide enthalten nur leere `components/`-Unterordner und keine echten Dateien.

Anschließend prüfen, dass keine verwaisten Referenzen mehr existieren:

```bash
rg -n "ContextsLive|ContextLive|contexts_live|context_live" lib/ test/
```

Falls die Suche Treffer liefert: prüfen, ob sie noch sinnvoll sind oder ebenfalls entfernt gehören. Auch in `priv/` und `assets/` kurz suchen.

## Betroffene Dateien

- `lib/ex_lingo_web/live/translations/contexts_live/` (Verzeichnis)
- `lib/ex_lingo_web/live/translations/context_live/` (Verzeichnis)
- ggf. weitere Funde aus der `rg`-Suche

## Akzeptanzkriterien

- Beide Verzeichnisse sind weg.
- `mix compile --warnings-as-errors` läuft sauber.
- `mix test` läuft grün.
- Keine `ContextsLive`/`ContextLive`-Referenzen mehr im Code.

## Out of Scope

- Das Datenmodell hinter `message.context` (das ist Gettext-Context und bleibt zwingend).
- Der `UnclearTextsLive`-Workflow (unclear texts — die Funktion bleibt).
