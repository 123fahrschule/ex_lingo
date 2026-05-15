## 1. Core Detection

- [x] 1.1 Add a possible duplicate candidate data shape or documented map contract for group metadata and occurrences.
- [x] 1.2 Implement a core service/finder that lists possible duplicate groups for a target locale.
- [x] 1.3 Implement effective target text selection using non-empty `translated_text` with fallback to non-empty `original_text`.
- [x] 1.4 Implement normalization for exact source/target matches and loose source variants.
- [x] 1.5 Implement placeholder extraction and compatibility checks for `%{name}`-style interpolation variables.
- [x] 1.6 Keep singular translations separate from plural translations and keep plural `nplural_index` values separate.
- [x] 1.7 Add a helper that returns a message-id-to-candidate summary map for translation list badges.

## 2. Core Tests

- [x] 2.1 Test high-confidence detection for same source and target text across different scopes.
- [x] 2.2 Test target-only duplicate detection for short UI strings with compatible placeholders.
- [x] 2.3 Test loose source variant detection for whitespace, case, or trailing punctuation differences.
- [x] 2.4 Test exclusion of empty translations.
- [x] 2.5 Test placeholder mismatch behavior.
- [x] 2.6 Test that plural forms with different `nplural_index` values are not grouped together.

## 3. Possible Duplicates Page

- [x] 3.1 Add a dashboard route and LiveView for the possible duplicates page.
- [x] 3.2 Add sidebar navigation labeled `Possible duplicates` with German translation `Mögliche Duplikate`.
- [x] 3.3 Add locale selection or filtering for the possible duplicates page.
- [x] 3.4 Render grouped candidates with source text, target text, occurrence count, reason, confidence, scopes, and source references.
- [x] 3.5 Add empty state and loading/error states consistent with existing dashboard screens.

## 4. Translation Workflow Integration

- [x] 4.1 Load duplicate candidate summaries in `TranslationsLive` for the current locale and visible message page.
- [x] 4.2 Render a possible duplicate badge in message rows that belong to duplicate groups.
- [x] 4.3 Load duplicate candidate details through the translation editor flow for the current message and locale.
- [x] 4.4 Render duplicate details near the existing message metadata in singular translation edit mode.
- [x] 4.5 Render duplicate details near the existing message metadata in plural translation edit mode.
- [x] 4.6 Ensure duplicate indicators do not change existing stale, merge, save, or AI suggestion behavior.

## 5. UI Copy And Verification

- [x] 5.1 Add English source strings and German translations for duplicate review UI copy.
- [x] 5.2 Add LiveView/component tests for the possible duplicates page.
- [x] 5.3 Add tests for duplicate badges in the translation list.
- [x] 5.4 Add tests for duplicate details in translation editor views.
- [x] 5.5 Run formatter and the relevant ExUnit test files.
- [x] 5.6 Add copyable AI cleanup instructions with tests for semantic-review guardrails.
