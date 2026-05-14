## ADDED Requirements

### Requirement: Request translation suggestion
The system SHALL allow users to request an AI translation suggestion from the translation edit screen.

The request MUST use `message.msgid` as the source text and the current ExLingo locale as the target locale.

#### Scenario: Request singular suggestion
- **WHEN** a user requests an AI suggestion for a singular translation
- **THEN** the system sends the message source text, target locale, message metadata, and relevant glossary entries to the configured provider

#### Scenario: Request plural suggestion
- **WHEN** a user requests an AI suggestion for the current plural form
- **THEN** the system sends the message source text, target locale, plural form index, plural examples, message metadata, and relevant glossary entries to the configured provider

### Requirement: Display suggestion text only
The system SHALL display only the suggested translation text returned by the provider.

The system MUST NOT display confidence, notes, rationale, or other provider metadata as part of the suggestion workflow.

#### Scenario: Provider returns suggestion
- **WHEN** the provider returns a successful suggestion
- **THEN** the UI displays the suggested translation text without additional AI metadata

#### Scenario: Provider includes unsupported metadata
- **WHEN** a provider implementation has internal metadata
- **THEN** the user-facing suggestion still displays only the translation text

### Requirement: Accept suggestion directly
The system SHALL allow users to accept an AI suggestion directly.

Accepting a suggestion MUST persist the suggestion into the current translation's `translated_text` field using the existing singular or plural translation update flow.

#### Scenario: Accept singular suggestion
- **WHEN** a user accepts a singular suggestion
- **THEN** the system saves the suggestion as the singular translation text

#### Scenario: Accept plural suggestion
- **WHEN** a user accepts a suggestion for a plural form
- **THEN** the system saves the suggestion for the current plural form only

### Requirement: Adapt suggestion before saving
The system SHALL allow users to adapt an AI suggestion before persisting it.

#### Scenario: User adapts suggestion
- **WHEN** a user chooses to adapt a suggestion
- **THEN** the system places the suggestion into an editable field without saving it immediately

#### Scenario: User saves adapted suggestion
- **WHEN** a user saves the adapted suggestion
- **THEN** the system persists the edited text as the current translation

### Requirement: Do not overwrite without explicit action
The system SHALL NOT overwrite an existing translation unless the user explicitly accepts or saves a suggestion.

#### Scenario: Suggestion generated for existing translation
- **WHEN** the provider returns a suggestion while the translation already has text
- **THEN** the existing translation remains unchanged until the user accepts or saves the suggestion

### Requirement: Handle unavailable suggestion provider
The system SHALL handle missing or failing AI providers without changing translation data.

#### Scenario: Provider is not configured
- **WHEN** a user requests a suggestion and no provider is configured
- **THEN** the system shows an actionable error and leaves the translation unchanged

#### Scenario: Provider request fails
- **WHEN** the configured provider returns an error
- **THEN** the system shows an error and leaves the translation unchanged

### Requirement: Control automatic suggestion generation
The system SHALL make automatic suggestion generation configurable.

Automatic generation MUST be disabled unless explicitly enabled by configuration.

#### Scenario: Automatic generation disabled
- **WHEN** a user opens a translation edit screen and automatic generation is disabled
- **THEN** the system does not call an AI provider until the user requests a suggestion

#### Scenario: Automatic generation enabled for missing translation
- **WHEN** a user opens a missing translation and automatic generation is enabled for missing translations
- **THEN** the system may request a suggestion automatically
