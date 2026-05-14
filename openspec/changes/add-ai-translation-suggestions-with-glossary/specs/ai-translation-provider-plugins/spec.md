## ADDED Requirements

### Requirement: Define provider contract
The system SHALL define a provider contract for AI translation suggestion plugins.

The provider contract MUST accept a normalized suggestion request and return either a successful translation text string or an error.

#### Scenario: Provider returns suggestion text
- **WHEN** a provider successfully generates a suggestion
- **THEN** it returns only the suggested translation text to ExLingo

#### Scenario: Provider returns error
- **WHEN** a provider cannot generate a suggestion
- **THEN** it returns an error that ExLingo can show without changing translation data

### Requirement: Build normalized suggestion request
The system SHALL build a provider request containing the information needed for a translation suggestion.

The request MUST include source locale, target locale, source text, message type, message metadata, current translation state, and matched glossary entries.

#### Scenario: Request contains relevant glossary entries
- **WHEN** glossary entries match the current language direction, source text, and scope
- **THEN** the provider request includes those glossary entries

#### Scenario: Request excludes irrelevant glossary entries
- **WHEN** glossary entries do not match the current language direction, source text, or scope
- **THEN** the provider request excludes those glossary entries

### Requirement: Keep provider output minimal
Provider plugins SHALL instruct external AI services to return only the translation suggestion text.

Provider plugins MUST NOT require confidence, notes, rationale, or JSON metadata for the standard suggestion workflow.

#### Scenario: OpenAI prompt is built
- **WHEN** the OpenAI provider builds a request
- **THEN** its prompt instructs the model to return only the final translation text

#### Scenario: Provider output contains only text
- **WHEN** ExLingo receives a successful provider response
- **THEN** ExLingo treats the response as the complete suggestion text

### Requirement: Configure OpenAI provider
The system SHALL allow OpenAI provider configuration through plugin options.

OpenAI configuration MUST support an API key, default model, allowed model list, and endpoint override.

#### Scenario: API key from environment
- **WHEN** the OpenAI plugin is configured to read `OPENAI_API_KEY`
- **THEN** the provider uses the environment variable value for OpenAI requests

#### Scenario: Model selection
- **WHEN** multiple allowed OpenAI models are configured
- **THEN** the suggestion UI allows the user or configured default to select one of the allowed models

#### Scenario: Invalid model selection
- **WHEN** a request selects a model outside the allowed model list
- **THEN** the provider rejects the request before calling OpenAI

### Requirement: Support future providers
The system SHALL allow additional provider plugins to implement the same suggestion contract.

Future provider plugins MUST be able to use the same normalized request shape and return the same minimal suggestion response.

#### Scenario: Google Cloud AI provider is configured
- **WHEN** a Google Cloud AI provider plugin implements the contract and is configured
- **THEN** ExLingo can request suggestions through that provider without changing glossary behavior

#### Scenario: Local provider is configured
- **WHEN** a local provider such as Ollama implements the contract and is configured
- **THEN** ExLingo can request suggestions through that provider without changing glossary behavior

### Requirement: Validate provider configuration
The system SHALL validate provider plugin configuration during startup or before the first suggestion request.

#### Scenario: Missing provider credentials
- **WHEN** provider credentials are missing
- **THEN** the provider reports a configuration error without attempting an external request

#### Scenario: Valid provider configuration
- **WHEN** provider credentials and model configuration are valid
- **THEN** the provider is available for suggestion requests
