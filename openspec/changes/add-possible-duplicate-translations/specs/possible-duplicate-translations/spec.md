## ADDED Requirements

### Requirement: Detect possible duplicate translation groups
The system SHALL detect possible duplicate translation groups for a selected target locale by analyzing active ExLingo messages and their effective translated text.

The effective translated text MUST use `translated_text` when it is non-empty and MUST fall back to `original_text` when `translated_text` is empty. Messages without effective translated text MUST be excluded from duplicate candidate groups.

Singular translations and plural translations MUST be evaluated separately. Plural candidate groups MUST include the plural form index and MUST NOT mix different `nplural_index` values.

#### Scenario: Same source and target across different scopes
- **WHEN** two active singular messages for locale `de` use the same normalized `msgid` and the same effective translated text but have different domain, context, or application source scope
- **THEN** the system reports one possible duplicate group containing both messages

#### Scenario: Same target across short source strings
- **WHEN** multiple active messages for locale `de` have different short source strings but the same effective translated text
- **THEN** the system reports a possible duplicate group when the messages pass placeholder and plural compatibility checks

#### Scenario: Empty translations are excluded
- **WHEN** a message has neither `translated_text` nor `original_text` for the selected locale
- **THEN** the system excludes that message from possible duplicate detection

#### Scenario: Plural forms are isolated
- **WHEN** two plural translations share the same effective translated text but use different `nplural_index` values
- **THEN** the system does not group those plural translations together

### Requirement: Classify duplicate candidate reason and confidence
The system SHALL assign every possible duplicate group a reason and confidence value.

The reason MUST explain the matching rule that produced the group. The confidence MUST allow the UI to distinguish strong cleanup candidates from semantic review candidates.

#### Scenario: Exact source and target match
- **WHEN** a possible duplicate group has the same normalized source text and target text across multiple scopes
- **THEN** the system marks the group with reason `same_source_same_target_different_scope` and high confidence

#### Scenario: Target-only match
- **WHEN** a possible duplicate group has different source strings and the same target text
- **THEN** the system marks the group with reason `same_target_different_source` and lower confidence than an exact source and target match

#### Scenario: Source variant match
- **WHEN** a possible duplicate group differs only by source text whitespace, case, or trailing punctuation after loose normalization
- **THEN** the system marks the group with reason `near_source_variant_same_target`

### Requirement: Respect interpolation placeholders
The system SHALL compare gettext interpolation placeholders when evaluating possible duplicate groups.

Candidate groups MUST NOT be high confidence when source or target placeholder sets are incompatible.

#### Scenario: Matching placeholders
- **WHEN** candidate messages use the same placeholder names in their source and target texts
- **THEN** the system may include them in a duplicate group using the normal confidence for their matching rule

#### Scenario: Mismatched placeholders
- **WHEN** candidate messages use incompatible placeholder names such as `%{name}` and `%{count}`
- **THEN** the system excludes them from high-confidence duplicate groups

### Requirement: Expose possible duplicates dashboard page
The system SHALL expose a dashboard page for reviewing possible duplicate translation groups.

The page MUST be reachable from dashboard navigation using the English label `Possible duplicates` and the German label `Mögliche Duplikate`. The page MUST allow users to choose or filter by target locale.

Each duplicate group MUST show the source text, effective translated text, occurrence count, reason, confidence, affected message scopes, and source positions when available.

Each duplicate group MUST provide a copyable AI cleanup instruction for use in the actual application repository. The instruction MUST state that the affected code locations need to be reviewed first and that application i18n/gettext keys MUST only be consolidated when the semantics are fully identical.

#### Scenario: User opens possible duplicates page
- **WHEN** a user opens the possible duplicates dashboard page
- **THEN** the system displays possible duplicate groups for the selected target locale

#### Scenario: User changes locale filter
- **WHEN** a user selects a different target locale on the possible duplicates page
- **THEN** the system refreshes the duplicate groups for that locale

#### Scenario: Source positions are available
- **WHEN** a duplicate group contains messages with source references
- **THEN** the system displays those source positions with the affected message details

#### Scenario: User copies AI cleanup instructions
- **WHEN** a user clicks the AI instruction copy action for a duplicate group
- **THEN** the system copies instructions that include the candidate metadata, source references or search hints, and a warning to consolidate only after semantic review

### Requirement: Show duplicate badge in translation list
The system SHALL show a duplicate badge in the translation list for messages that belong to at least one possible duplicate group for the current locale.

The badge MUST be advisory and MUST NOT block editing, saving, stale detection, or merge actions.

#### Scenario: Message has duplicate candidate
- **WHEN** a message in the translation list belongs to a possible duplicate group for the current locale
- **THEN** the system displays a possible duplicate badge in that message row

#### Scenario: Message has no duplicate candidate
- **WHEN** a message in the translation list does not belong to any possible duplicate group for the current locale
- **THEN** the system does not display the duplicate badge for that message row

#### Scenario: Badge coexists with stale and merge badges
- **WHEN** a message is stale, mergeable, and part of a possible duplicate group
- **THEN** the system may display the duplicate badge alongside existing stale and merge indicators without changing their actions

### Requirement: Show duplicate details in translation editor
The system SHALL show possible duplicate details in the translation editor when the current message belongs to a duplicate group for the current locale.

The detail view MUST list related messages, their scopes, effective translated text, reason, confidence, and source positions when available.

The detail view MUST expose the same copyable AI cleanup instruction as the possible duplicates page.

#### Scenario: Editor opens for duplicate candidate
- **WHEN** a user opens the translation editor for a message that belongs to a possible duplicate group
- **THEN** the system displays duplicate details near the existing message metadata

#### Scenario: Editor opens for non-duplicate message
- **WHEN** a user opens the translation editor for a message that does not belong to any possible duplicate group
- **THEN** the system does not display duplicate details

### Requirement: Keep duplicate suggestions read-only
The system SHALL keep possible duplicate suggestions read-only in the first version.

The system MUST NOT automatically merge messages, update translations, delete records, or rewrite application code from the duplicate review UI.

#### Scenario: User reviews duplicate group
- **WHEN** a user reviews a possible duplicate group
- **THEN** the system allows inspection of candidate details without mutating translation data

#### Scenario: User edits translation normally
- **WHEN** a user saves a translation from a message that has a duplicate badge
- **THEN** the system saves the translation through the existing translation update flow
