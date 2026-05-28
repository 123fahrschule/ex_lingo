# 07 — Bild-Upload als Kontext (S3)

## Voraussetzung

Briefing 06 (Settings + S3-Credentials-Felder) muss durch sein. Dieses Briefing nutzt die dort angelegten Settings.

## Ziel

Übersetzer brauchen oft visuellen Kontext: "Wie sieht der String 'Buchen' im UI aus?". Ein Screenshot/Mockup pro Message ist viel schneller verständlich als jede Source-Position. Heroku-Deploy schließt lokalen Upload aus → S3.

## Was tun

### 1. Schema `ex_lingo_message_images`

Migration anlegen (Versionsschema von ExLingo-Migrationen folgen, siehe Briefing 06):

- `id`
- `message_id` (FK auf `ex_lingo_messages`, `on_delete: :delete_all`)
- `s3_key` (text) — der relative Object-Key im Bucket, z. B. `messages/<message_id>/<uuid>.png`
- `content_type` (text)
- `byte_size` (bigint)
- `uploaded_by` (text, nullable) — optional, falls Auth später kommt
- `inserted_at`, `updated_at`

Eine Message kann mehrere Bilder haben. Reihenfolge: nach `inserted_at`.

Schema-Modul `lib/ex_lingo/translations/message_image.ex`, plus Context-Funktionen in `lib/ex_lingo/translations/messages/`:

- `list_images(message_id)`
- `create_image(message_id, %{s3_key, content_type, byte_size})`
- `delete_image(image_id)`

### 2. S3-Client

Bibliothek: **`ex_aws` + `ex_aws_s3`** (Standard im Phoenix-Umfeld). In `mix.exs` ergänzen und in der `application.ex` ggf. konfigurieren.

Konfiguration **nicht statisch** über `config/runtime.exs`, sondern dynamisch aus `ExLingo.Settings.get()`. Helper-Modul `lib/ex_lingo/storage/s3.ex` mit:

```elixir
ExLingo.Storage.S3.config()                # baut ExAws-Config aus den Settings
ExLingo.Storage.S3.put(key, binary, content_type)
ExLingo.Storage.S3.delete(key)
ExLingo.Storage.S3.presigned_url(key, opts)   # für Anzeige im Browser
ExLingo.Storage.S3.test_connection()          # für den "Test connection"-Button aus Briefing 06
```

Presigned URLs (Read), Gültigkeit z. B. 1h. Bilder sollen **nicht public** sein.

### 3. Upload-UI im Translation-Editor

**Wichtig:** Briefing 05 stellt den Editor von Vollseite/Flyout auf Inline um. Die Bild-UI muss inline funktionieren — am besten als ausklappbarer Bereich in der Zeile.

Pro Zeile (Message) ein Icon-Button "Images" mit Counter (z. B. "📎 3"). Klick öffnet einen kleinen Inline-Bereich oder Popover mit:

- Thumbnail-Grid der vorhandenen Bilder (lädt Bilder via presigned URL).
- Drag-and-Drop-Zone für neue Uploads.
- File-Input als Fallback.
- Pro Bild ein "Delete"-Button.

LiveView-Upload-Mechanismus: `allow_upload/3` mit `external: &presign_upload/2` — Phoenix-LiveView unterstützt direkten Browser→S3-Upload via Presigned-POST, sodass die Datei nicht über den Server muss (wichtig für Heroku-Limits). Dokumentation: [hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#allow_upload/3](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#allow_upload/3).

Constraints:

- `accept: ~w(.png .jpg .jpeg .webp)`
- `max_entries: 10`
- `max_file_size: 5 * 1024 * 1024` (5 MB pro Bild)

Nach erfolgreichem Upload: in DB `create_image/2` aufrufen mit dem finalen S3-Key.

### 4. Anzeige

In der Übersetzungs-Zeile: kleines Thumbnail neben dem Source-Text (oder direkt über/unter dem Translation-Input). Klick auf Thumbnail öffnet Lightbox/Modal mit großer Ansicht.

Performance: Liste der Image-Counts pro Message als preload mitlesen (analog zu `possible_duplicate_summaries` heute), damit nicht pro Zeile ein extra Query passiert.

### 5. Löschen

Beim Löschen eines Bildes: zuerst aus S3 (`Storage.S3.delete/1`), dann aus DB. Bei S3-Fehler: DB-Eintrag behalten, Fehler-Toast — sonst kriegt man Karteileichen, die schwer aufzuräumen sind.

Beim Löschen einer Message (Stale-Cleanup, Merge): zugehörige Bilder ebenfalls aus S3 entfernen. Falls Merge in Briefing-Liste landet (heute fuzzy-merge `merge_messages/2`): an dieser Stelle Bilder vom Source auf das Target übertragen oder mit-löschen, je nach Wunsch. **Empfehlung**: Bilder mit-übertragen (an target hängen), nicht löschen.

### 6. Sicherheit

- Settings-Seite ist heute ohne Auth — passt zur Architektur, soll aber dokumentiert sein (README-Hinweis).
- S3-Bucket-Berechtigungen: minimal, nur PutObject/GetObject/DeleteObject auf den definierten Prefix.
- Presigned URLs sollten kurze TTL haben (1h).

### 7. Tests

- `test/ex_lingo/translations/message_image_test.exs` — Schema, Context.
- `test/ex_lingo/storage/s3_test.exs` — Mit Mox / fake ExAws-Adapter (kein echter S3-Call in Tests).
- LiveView-Test, der Upload-Flow simuliert (LiveView-Upload-Test-Helpers).

## Betroffene Dateien

- Neue Migration unter `lib/ex_lingo/migrations/postgres/`
- `lib/ex_lingo/migration.ex` — Version erhöhen
- `lib/ex_lingo/translations/message_image.ex` (neu)
- `lib/ex_lingo/translations/messages/messages.ex` — Image-Context-Funktionen ergänzen
- `lib/ex_lingo/storage/s3.ex` (neu)
- `mix.exs` — `ex_aws`, `ex_aws_s3`, `hackney` oder `req` als Dep
- `lib/ex_lingo_web/live/translations/translations_live/components/messages_table/` — Thumbnail + Upload-UI inline (nach Briefing 05)
- `lib/ex_lingo_web/live/settings/settings_live.ex` — "Test connection"-Button live verdrahten
- Tests

## Akzeptanzkriterien

- In der Übersetzungs-Liste lassen sich pro Message Bilder hochladen.
- Hochgeladene Bilder werden in S3 abgelegt (verifiziert: kein Plaintext im Repo, kein Heroku-Filesystem).
- Anzeige der Bilder im Editor funktioniert über presigned URLs.
- Löschen funktioniert (S3 + DB).
- "Test connection"-Button in Settings liefert Erfolg/Fehler-Feedback.
- Tests grün; LiveView-Upload-Test simuliert einen Upload erfolgreich.
- Migration vorwärts und rückwärts ausführbar.

## Out of Scope

- Image-Editor / Cropping in der UI.
- Mehrere Storage-Backends (z. B. Azure Blob, GCS). Nur S3.
- AI-Bildanalyse / OCR.
- Bilder im AI-Suggestion-Prompt mitschicken (GPT-Vision o. ä.) — gerne später als eigenes Briefing.
- Versionierung / History der Uploads.
