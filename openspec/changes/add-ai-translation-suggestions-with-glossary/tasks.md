## 1. Glossary Data Model

- [x] 1.1 Add PostgreSQL migration support for `ex_lingo_glossary_entries`.
- [x] 1.2 Add `ExLingo.Translations.GlossaryEntry` schema with required language direction and term fields.
- [x] 1.3 Add glossary context modules, finders, create/update/delete functions, and delegates in `ExLingo.Translations`.
- [x] 1.4 Add tests for glossary CRUD, validations, and migration compatibility.

## 2. Glossary Matching

- [x] 2.1 Add a glossary matching service that receives source locale, target locale, source text, and message metadata.
- [x] 2.2 Filter glossary entries by language direction and exclude irrelevant target locales.
- [x] 2.3 Filter glossary entries by source term presence in `message.msgid`.
- [x] 2.4 Filter and order glossary entries by domain, context, and application source scope specificity.
- [x] 2.5 Add tests for language-direction filtering, source-term filtering, scope filtering, and specificity ordering.

## 3. Glossary UI

- [x] 3.1 Add glossary dashboard routes and sidebar navigation.
- [x] 3.2 Add glossary list UI with language direction, terms, usage guidance, scope, and actions.
- [x] 3.3 Add glossary create/edit/delete UI using existing ExLingo component patterns.
- [x] 3.4 Add UI tests or LiveView tests for glossary listing and form behavior.

## 4. Provider Contract

- [x] 4.1 Add normalized AI suggestion request and provider result structs or typed maps.
- [x] 4.2 Add provider behaviour for `suggest_translation/1` returning only suggestion text or an error.
- [x] 4.3 Add provider configuration validation for required credentials, allowed models, and default model.
- [x] 4.4 Add tests for provider contract success and error behavior.

## 5. Suggestion Workflow

- [x] 5.1 Add a suggestion service that builds requests from message, locale, current translation, plural metadata, and matched glossary entries.
- [x] 5.2 Add a translation form plugin component for requesting AI suggestions.
- [x] 5.3 Display only the suggested translation text in the translation form.
- [x] 5.4 Add direct accept behavior that persists the suggestion to the current singular or plural translation.
- [x] 5.5 Add adapt-before-saving behavior that copies the suggestion into an editable field without immediate persistence.
- [x] 5.6 Add missing-provider and provider-error handling without mutating translation data.
- [x] 5.7 Add tests for request, display, accept, adapt, and error flows.

## 6. OpenAI Provider Plugin

- [x] 6.1 Add OpenAI provider plugin module and supervision/config integration.
- [x] 6.2 Add OpenAI HTTP client implementation with configurable endpoint and API key source.
- [x] 6.3 Add configurable allowed model list and default low-cost model selection.
- [x] 6.4 Build OpenAI prompts that include relevant glossary entries and require translation text only.
- [x] 6.5 Parse OpenAI responses into a plain suggestion string and reject empty responses.
- [x] 6.6 Add tests for OpenAI request payloads, model validation, response parsing, and failure handling.

## 7. Documentation And Verification

- [x] 7.1 Document glossary usage and provider-plugin configuration examples.
- [x] 7.2 Document OpenAI configuration with `OPENAI_API_KEY`, model selection, and endpoint override.
- [x] 7.3 Document the provider contract for future Google Cloud AI, Ollama, and other provider plugins.
- [x] 7.4 Run formatting, unit tests, and relevant LiveView tests.
- [x] 7.5 Run OpenSpec validation for this change.
