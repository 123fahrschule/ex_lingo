## ADDED Requirements

### Requirement: Manage glossary entries
The system SHALL allow users to manage glossary entries in ExLingo core.

Each glossary entry MUST include a source locale, target locale, source term, and target term. Each glossary entry MAY include usage guidance and optional references to an ExLingo domain, context, and application source.

#### Scenario: Create glossary entry
- **WHEN** a user creates a glossary entry for source locale `en`, target locale `de`, source term `Certificate`, and target term `Ausbildungsnachweis`
- **THEN** the system persists the glossary entry with the configured language direction and terms

#### Scenario: Edit glossary entry
- **WHEN** a user changes the target term of an existing glossary entry
- **THEN** future glossary lookups use the updated target term

#### Scenario: Delete glossary entry
- **WHEN** a user deletes a glossary entry
- **THEN** future glossary lookups exclude that entry

### Requirement: Match glossary by language direction
The system SHALL match glossary entries only when the entry source locale and target locale match the current translation request.

#### Scenario: Matching English to German
- **WHEN** the current translation request uses source locale `en` and target locale `de`
- **THEN** the system includes matching `en` to `de` glossary entries

#### Scenario: Excluding German glossary for English to Hungarian
- **WHEN** the current translation request uses source locale `en` and target locale `hu`
- **THEN** the system excludes glossary entries whose target locale is `de`

#### Scenario: Excluding German glossary for English cleanup
- **WHEN** the current translation request uses source locale `en` and target locale `en`
- **THEN** the system excludes glossary entries whose target locale is `de`

### Requirement: Match glossary by source text
The system SHALL include only glossary entries whose source term appears in the current source text.

The match MUST be case-insensitive by default.

#### Scenario: Source term appears in message
- **WHEN** the source text contains `Certificate`
- **THEN** the system includes relevant glossary entries for `Certificate`

#### Scenario: Source term absent from message
- **WHEN** the source text does not contain `Certificate`
- **THEN** the system excludes glossary entries for `Certificate`

### Requirement: Match glossary by scope
The system SHALL apply glossary entry scopes using the current message's domain, context, and application source.

Unscoped glossary entries MUST match all messages for the same language direction. Scoped glossary entries MUST match only when every configured scope field matches the current message.

#### Scenario: Global glossary entry
- **WHEN** a glossary entry has no domain, context, or application source scope
- **THEN** the system can use it for any message with the same matching language direction and source term

#### Scenario: Scoped glossary entry matches
- **WHEN** a glossary entry is scoped to the current message domain
- **THEN** the system can use that glossary entry for the request

#### Scenario: Scoped glossary entry does not match
- **WHEN** a glossary entry is scoped to a different application source than the current message
- **THEN** the system excludes that glossary entry from the request

### Requirement: Prefer specific glossary entries
The system SHALL order matched glossary entries by scope specificity before provider request construction.

More specific entries MUST appear before less specific entries when the same source term has multiple possible target terms.

#### Scenario: Scoped and global entry both match
- **WHEN** a scoped and an unscoped glossary entry both match `Certificate`
- **THEN** the scoped entry appears before the unscoped entry in the matched glossary list

### Requirement: Expose glossary management UI
The system SHALL expose glossary management screens in the ExLingo dashboard.

#### Scenario: User opens glossary page
- **WHEN** a user navigates to the ExLingo glossary section
- **THEN** the system displays glossary entries with language direction, terms, optional scope, and actions

#### Scenario: User filters glossary entries
- **WHEN** a user filters glossary entries by source locale or target locale
- **THEN** the system displays only entries matching the selected filter
