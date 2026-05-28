# 06 — Settings-Seite + konfigurierbare AI-Prompts

## Ziel

Heute steckt der OpenAI-System-Prompt hardcoded in `lib/ex_lingo/ai/providers/open_ai.ex` (Zeile 128–135): "You are a translation assistant for software product text in the driving school domain.". Das soll konfigurierbar werden.

Außerdem braucht ExLingo generell einen Settings-Bereich, in dem auch zukünftig weitere Konfigurationen (S3-Credentials in Briefing 07, später ggf. mehr) landen.

## Was tun

### 1. Navigations-Eintrag

In der Sidebar (links) ganz unten, **optisch abgetrennt** (z. B. Trennlinie + etwas Abstand) ein neuer Eintrag "Settings" / "Einstellungen". Pfad: `/settings`.

Wo das gerendert wird: Layout/Sidebar-Komponente — vermutlich `lib/ex_lingo_web/components/` oder direkt im Dashboard-Layout. Bitte suchen, wo die anderen Nav-Einträge (Dashboard, Locales, Glossary, Possible Duplicates, Unclear Texts) definiert sind, und dort konsistent ergänzen, aber mit Abstand/Trenner.

### 2. Schema für Settings

**Single-Row-Approach** (KV ist Overkill, da die Felder fest sind): eine Tabelle `ex_lingo_settings` mit einer einzigen Zeile. Migration via ExLingo-Migration-Versions-System (`ExLingo.Migration` und Verzeichnis `lib/ex_lingo/migrations/`).

Felder:

- `id` (Primärschlüssel, immer 1)
- `ai_system_prompt_global` (text, nullable) — globaler System-Prompt
- `ai_system_prompt_per_locale` (map/jsonb) — pro Locale-Code (z. B. `%{"de" => "...", "fr" => "..."}`)
- `s3_access_key_id` (text, nullable) — für Briefing 07
- `s3_secret_access_key_encrypted` (binary, nullable) — verschlüsselt, siehe unten
- `s3_bucket` (text, nullable)
- `s3_region` (text, nullable)
- `inserted_at`, `updated_at`

**Verschlüsselung des S3-Secrets**: Cloak.Ecto verwenden oder, wenn das zu viel Abhängigkeit ist, eigene AES-GCM-Verschlüsselung mit einem Key aus `:ex_lingo` Config (z. B. `secret_key_base` der App oder eigenem `:ex_lingo, :settings_encryption_key`). Klartext-Speicherung explizit verboten. Briefing 07 bezieht sich darauf.

Schema-Modul: `lib/ex_lingo/settings.ex` und `lib/ex_lingo/settings/settings.ex` (oder eine Datei, je nach Stil der Codebase — siehe `lib/ex_lingo/translations/`-Aufbau).

Context-Funktionen:

```elixir
ExLingo.Settings.get()           # liefert die Single-Row, legt sie ggf. lazy an
ExLingo.Settings.update(attrs)   # update + invalidate cache
ExLingo.Settings.ai_prompt_for(locale_code)
# Liefert kaskadierend: per_locale[locale_code] || global || nil
```

### 3. Settings-LiveView

`lib/ex_lingo_web/live/settings/settings_live.{ex,html.heex}`. Layout: gruppierte Sections.

- **Section "AI translation prompts"**
  - Textarea: "Global system prompt"
  - Hinweis-Text: "Used for all locales unless overridden below."
  - Pro Locale (Liste aus `Translations.list_locales/0`): kleines Card mit Textarea, leer = global wird verwendet.
- **Section "S3 storage"** (für Briefing 07 vorbereitet, kann mit leeren Inputs schon stehen)
  - Access Key ID (Text)
  - Secret Access Key (Password-Feld, beim Speichern verschlüsseln; Anzeige-Wert: leer oder maskiert)
  - Bucket
  - Region (Dropdown oder Text)
  - "Test connection"-Button — versucht ein simples `HEAD` auf den Bucket, zeigt Erfolg/Fehler-Toast.

Save: ein gemeinsamer "Save"-Button pro Section, oder ein globaler Save unten. Empfehlung: pro Section ein Save, damit man Teile unabhängig bearbeiten kann.

Router-Eintrag in `lib/ex_lingo_web/router.ex` ergänzen (analog zu den anderen Live-Routes im Dashboard-Scope):

```elixir
scope "/settings", Settings do
  live "/", SettingsLive, :index, route_opts
end
```

### 4. OpenAI-Provider anpassen

`lib/ex_lingo/ai/providers/open_ai.ex` — Funktion `system_prompt/0` durch `system_prompt/1` ersetzen, die die `SuggestionRequest` bekommt (oder zumindest `target_locale`):

```elixir
defp system_prompt(%SuggestionRequest{target_locale: locale}) do
  ExLingo.Settings.ai_prompt_for(locale) || default_system_prompt()
end

defp default_system_prompt do
  """
  You are a translation assistant. Return only the final translation text.
  Do not include Markdown, labels, quotes, notes, confidence, rationale, or alternatives.
  Follow glossary terminology when relevant.
  """
end
```

Hinweis: Der bisherige Hardcoded-Prompt enthält "driving school domain" — das ist 123fs-spezifisch. **Der neue Default soll generisch sein** (siehe oben), das 123fs-Wording wird beim ersten Start in den `ai_system_prompt_global`-DB-Wert geseedet (Seed in der Migration oder via `ExLingo.Settings.get()`-Lazy-Init), damit nichts verloren geht.

### 5. Cache

`ExLingo.Settings.get()` sollte gecached werden (ETS oder `:persistent_term`), Invalidate bei `update/1`. Sonst pro AI-Request ein DB-Roundtrip.

### 6. Tests

- `test/ex_lingo/settings_test.exs` — Get/Update/Cascading-Lookup.
- `test/ex_lingo_web/live/settings/settings_live_test.exs` — Form rendern, speichern, Anzeige.
- `test/ex_lingo/ai/providers/open_ai_test.exs` — anpassen, falls Prompts dort getestet werden.

## Betroffene Dateien

- Neue Migration unter `lib/ex_lingo/migrations/postgres/` (nächste Version-Nummer)
- `lib/ex_lingo/migration.ex` — Version-Konstante erhöhen (heute v6, dann v7)
- `lib/ex_lingo/settings.ex` (neu)
- `lib/ex_lingo/settings/settings.ex` (neu) — Schema
- `lib/ex_lingo_web/live/settings/settings_live.{ex,html.heex}` (neu)
- `lib/ex_lingo_web/router.ex` — Route ergänzen
- `lib/ex_lingo/ai/providers/open_ai.ex` — `system_prompt` umbauen
- Sidebar/Layout-Komponente — neuer Nav-Eintrag (Pfad nach Code-Suche)
- README — Hinweis auf Settings-Section ergänzen

## Akzeptanzkriterien

- `/settings` ist erreichbar, Nav-Eintrag ist da und optisch abgetrennt.
- Globaler Prompt + pro-Locale-Overrides sind speicherbar und werden persistiert.
- AI-Übersetzungs-Suggestion verwendet den aus DB geladenen Prompt (Locale-spezifisch falls gesetzt, sonst global, sonst Default).
- Beim ersten Migrieren wird der bisherige 123fs-Wording-Prompt als globaler Default geseedet (kein Datenverlust).
- S3-Felder existieren im Schema und in der UI (Funktionalität wird in Briefing 07 verdrahtet).
- Secret-Felder werden verschlüsselt gespeichert.
- Tests grün, Migration vorwärts und rückwärts ausführbar.

## Out of Scope

- Multi-Tenant / mehrere Apps in einem ExLingo. Andreas erwartet das nicht.
- Per-Domain-Prompts (bewusst weggelassen).
- User-Authentifizierung für Settings-Zugriff (heute gibt's das in ExLingo nicht — bleibt offen, falls später nötig).
- DeepL-/OpenAI-API-Key in den Settings UI. Heute über Config — kann ein späteres Briefing werden.

## Hinweise an Code

- Migration-Mechanismus von ExLingo ist Oban-style mit Versions-Up/Down — siehe `lib/ex_lingo/migration.ex` und `lib/ex_lingo/migrations/postgres/`. Sehr genau dem Muster der bisherigen Migrationen folgen.
- Bei Cloak: prüfen ob in `mix.exs` schon ähnliche Abhängigkeiten — falls nicht, bewusst entscheiden ob neue Dep aufnehmen oder eigene Mini-Krypto.
