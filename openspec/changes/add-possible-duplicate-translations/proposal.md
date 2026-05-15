## Why

Developers and translators currently only see duplicate translation patterns if they run a separate report or manually notice repeated strings. That makes cleanup easy to forget, especially for small UI labels such as "Cancel" that are translated repeatedly across domains, contexts, or application sources.

ExLingo should surface possible duplicate translations directly in the dashboard workflow so developers can notice them while translating, inspect the affected source positions, and decide whether the application code should use a shared gettext message.

## What Changes

- Add a read-only "Possible duplicates" dashboard section, translated in the German UI as "Mögliche Duplikate".
- Detect possible duplicate translation groups for a locale from existing messages and singular/plural translations.
- Show possible duplicate badges in the normal translation list for messages that belong to a duplicate group.
- Show duplicate details on the translation edit screen, including related messages, scope metadata, and source positions where available.
- Let developers copy a cautious AI cleanup instruction for a duplicate group so an assistant can inspect and refactor the application code.
- Classify suggestions by reason and confidence so developers can distinguish strong cleanup candidates from semantic review candidates.
- Keep duplicate suggestions advisory only; this change does not automatically merge messages or rewrite application code.

## Capabilities

### New Capabilities

- `possible-duplicate-translations`: Detects and displays possible duplicate translation groups in the ExLingo dashboard and translation workflow.

### Modified Capabilities

- None.

## Impact

- Core translation context gains query/service logic for duplicate candidate detection.
- Dashboard routing and navigation gain a "Possible duplicates" screen.
- Translation list and translation edit LiveViews receive duplicate candidate metadata.
- UI copy gains new English source strings and German translations for the duplicate review workflow.
- Duplicate detail UI gains a clipboard action that copies guarded AI instructions for manual code cleanup.
- Tests should cover duplicate detection rules, list badges, detail rendering, and the new dashboard route.
