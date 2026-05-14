## Why

Translators currently have to write or clean up every ExLingo translation manually, even when a low-cost AI model could provide a useful first draft. Fahrschule-specific terminology also needs consistent handling, because common source terms such as "Certificate" can require different approved German translations depending on product context.

## What Changes

- Add a core glossary for approved terminology with source locale, target locale, source term, target term, optional usage guidance, and optional scoping by existing ExLingo concepts such as domain, context, and application source.
- Add glossary management UI inside ExLingo so users can create, edit, delete, and review glossary entries.
- Add an AI translation suggestion flow on the translation edit screen.
- The AI suggestion result exposed to users is only the suggested translation text. Confidence scores, notes, explanations, and similar metadata are out of scope unless later required for debugging or evaluation.
- Glossary entries are included in AI requests only when their language direction and scope are relevant to the current translation.
- Add a provider contract so AI providers can be supplied by plugins. The first provider is OpenAI; later providers such as Google Cloud AI, Ollama, or other local/free providers can use the same contract.
- Add OpenAI configuration for API key and selectable low-cost models.

## Capabilities

### New Capabilities

- `translation-glossary`: Core glossary storage, management, and matching rules for terminology that should influence translations.
- `ai-translation-suggestions`: User-facing workflow for requesting, reviewing, accepting, adapting, and saving AI translation suggestions.
- `ai-translation-provider-plugins`: Provider-agnostic contract and configuration model for OpenAI and future AI translation providers.

### Modified Capabilities

- None.

## Impact

- Adds new ExLingo PostgreSQL database tables and migrations for glossary entries, with support for a configured PostgreSQL schema prefix.
- Adds new ExLingo context modules, finders, services, schemas, and LiveView screens for glossary management.
- Extends the translation edit view through the existing plugin/component mechanism.
- Adds provider-facing request/response structs or behaviours for AI suggestion plugins.
- Adds an OpenAI provider plugin and configuration options for API key, endpoint, and model selection.
- Adds tests for glossary matching, provider contract behavior, prompt/request construction, and translation form interactions.
