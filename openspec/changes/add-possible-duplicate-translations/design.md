## Context

ExLingo already imports gettext messages into `ex_lingo_messages`, stores locale-specific singular and plural translations, and records source positions on each message. The translation list already displays review badges for stale and mergeable messages, and the translation edit flow already shows message scope metadata plus source positions.

Possible duplicate translations are different from stale-message merges. A stale merge repairs database records after a source message changed. A possible duplicate is an advisory cleanup signal: multiple active messages may represent the same UI concept and might be better expressed as one shared gettext message in the application code.

## Goals / Non-Goals

**Goals:**

- Surface possible duplicate translations in the normal dashboard workflow.
- Provide a dedicated "Possible duplicates" page, translated to German as "Mögliche Duplikate".
- Add lightweight duplicate badges in the translation list.
- Show enough detail in the edit screen for a developer to inspect related messages and source references.
- Keep candidate detection deterministic, explainable, and cheap enough for dashboard use.
- Avoid suggesting unsafe cleanup when placeholders or plural forms make strings incompatible.

**Non-Goals:**

- Automatically merge messages.
- Automatically rewrite application source code.
- Persist duplicate suggestions as separate database records.
- Build a translation memory or generic terminology system.
- Replace stale detection or fuzzy stale-message matching.

## Decisions

### Use "Possible duplicates" As The Product Label

The navigation item and page title will use "Possible duplicates" in English and "Mögliche Duplikate" in German.

Rationale: "Suggestions" is too broad and overlaps with existing AI translation suggestions. The duplicate page is a cleanup/review surface, not a translation generation feature.

Alternative considered: "Cleanup Suggestions". That describes the intent, but it is less direct when a developer sees a badge on one specific translation.

### Compute Suggestions On Demand

Duplicate candidates will be computed by a core service such as `ExLingo.Translations.PossibleDuplicateTranslations`. The service will query existing messages, singular translations, and plural translations for a target locale and return grouped candidate structs/maps.

Rationale: candidates are derived from current translation data and source references. Persisting them would require invalidation on message imports, translation edits, locale changes, and future source reference updates.

Alternative considered: store duplicate suggestions in a table. That would make list rendering cheap but introduces stale suggestion state and migration complexity without a clear product need.

### Keep Candidate Types Explicit

The service will classify candidates with a reason and confidence:

- `same_source_same_target_different_scope`: same normalized `msgid` and target text appear in multiple messages because domain, context, or application source differs.
- `same_target_different_source`: multiple short UI source strings share the same target text.
- `near_source_variant_same_target`: source strings normalize to the same loose value, for example whitespace, case, or trailing punctuation differences, and share a target text.

Rationale: the UI can show stronger candidates more prominently and explain why a badge appears. A developer should not have to infer whether the system saw a real duplicate or only a semantic coincidence.

Alternative considered: group only by translated text. That catches many cases but produces too many false positives, such as different English concepts legitimately translated to the same German word.

### Respect Locale, Plural Form, And Placeholders

Candidates are target-locale specific. Singular translations and plural translations are evaluated separately, and plural candidates include the `nplural_index` so plural forms are not mixed.

The detector will extract `%{name}`-style placeholders from source and target text. Candidates with incompatible placeholder sets will be excluded from high-confidence groups and either omitted or marked low-confidence only when the UI can explain the mismatch.

Rationale: replacing or sharing strings with different interpolation variables can break runtime rendering or change meaning.

Alternative considered: ignore placeholders in the first version. That would make the detector simpler but risky for strings such as "Delete %{name}" and "Delete %{count}".

### Use Effective Target Text

For duplicate analysis, each translation occurrence uses `translated_text` when it is non-empty and falls back to `original_text` when ExLingo has not overridden the PO text. Empty target text is excluded.

Rationale: developers need to see duplicate cleanup opportunities whether the text currently comes from PO files or from ExLingo's editable translation field.

Alternative considered: only analyze `translated_text`. That would miss projects that have many valid PO translations but few ExLingo overrides.

### Integrate With Existing Dashboard Surfaces

The implementation will add:

- A dashboard route such as `/possible_duplicates`.
- A sidebar item using an existing icon component.
- A LiveView page with locale filtering, confidence/reason filters, grouped candidates, and source references.
- A candidate map assigned into `TranslationsLive` so message rows can show a duplicate badge without per-row queries.
- Duplicate details in singular and plural edit screens, loaded through the translation editor path.

Rationale: the feature should be discoverable from navigation and unavoidable during translation work. Badges catch immediate workflow attention; the page supports systematic cleanup.

Alternative considered: only add a Mix task. That would make the feature easy to forget and would not help developers who are already working inside the translation UI.

### Keep The First Version Read-Only

The first version will not expose merge, delete, or "mark ignored" actions. It may expose a copy action that places an AI cleanup instruction on the clipboard, because that does not mutate ExLingo data or rewrite source code by itself.

Rationale: duplicate candidates are semantic review hints. The safe action is usually editing application gettext usage, not changing ExLingo database rows.

Alternative considered: allow "ignore" state in the dashboard. That can be useful later, but it requires persistence, user expectations around state, and invalidation behavior.

### Provide Guarded AI Cleanup Instructions

Each duplicate group will provide a "Copy AI instructions" action. The copied text is written for an AI running in the actual application repository, not inside ExLingo. It includes the candidate reason, confidence, effective translation, source strings, and source references or search hints.

The instruction explicitly tells the AI/developer to inspect the application code first and only consolidate application i18n/gettext keys when meaning, UI context, placeholders, plural form, grammar, and future change expectations are fully identical.

Rationale: developers need help turning a duplicate hint into source-code cleanup, but the UI must not imply that equal translations are automatically safe to merge.

## Risks / Trade-offs

- False positives from legitimate shared target words → show reason/confidence, source strings, scope, and references so the developer can decide quickly.
- Expensive grouping on large translation datasets → query only translated/effective text for selected locales, paginate the central page, and compute per-page badge maps for translation lists.
- Confusion with AI suggestions → use "Possible duplicates" / "Mögliche Duplikate" consistently and avoid the generic "Suggestions" label.
- Missing source references in imported PO files → still show message IDs, domains, contexts, and application sources; source references are optional details.
- Plural and interpolation edge cases → keep plural forms separate and exclude unsafe placeholder mismatches from high-confidence suggestions.

## Migration Plan

1. Add the core duplicate candidate service and tests.
2. Add the dashboard route, LiveView, navigation item, and translations.
3. Add duplicate badge metadata to the translation list.
4. Add duplicate detail panels to translation edit screens.
5. Add UI tests around the new route, badge display, and detail rendering.

Rollback removes the route/navigation and stops assigning duplicate metadata. No data migration is needed because suggestions are computed read-only.

## Open Questions

- Should the central page default to the first locale, all locales, or require selecting a locale?
- Should low-confidence `same_target_different_source` candidates be hidden by default?
- Should a later version support "ignored" candidates after developers review known false positives?
