## Context

ExLingo already has a plugin mechanism that starts configured plugin modules and renders plugin form components on singular and plural translation edit screens. The existing translation model stores `message.msgid` as the source gettext message and stores per-locale singular or plural `translated_text` values.

The new capability needs two different extension shapes:

- Glossary entries are core translation data and should live in ExLingo itself.
- AI providers are infrastructure choices and should stay replaceable through plugins.

The user-facing suggestion must be small and direct: a translation suggestion only. Confidence, notes, rationale, and other metadata are intentionally excluded from the product contract to avoid unused output tokens and UI noise.

## Goals / Non-Goals

**Goals:**

- Store Fahrschule-specific glossary terms in ExLingo core.
- Match glossary entries by source locale, target locale, current source text, and optional message scope.
- Provide AI suggestions in the existing translation form flow.
- Allow users to accept a suggestion immediately or adjust it before saving.
- Let OpenAI be configured as the first provider while allowing later providers such as Google Cloud AI, Ollama, or other services.
- Keep provider output contract minimal: the provider returns only suggested translation text.

**Non-Goals:**

- Build a translation memory or automatic batch translation workflow.
- Store AI suggestions as historical records.
- Add confidence scores, explanations, notes, or scoring metadata to the user-facing response.
- Fine-tune models or train custom models.
- Make glossary entries relevant across unrelated language directions.

## Decisions

### Glossary Belongs To Core

Add a core `translation-glossary` capability backed by ExLingo migrations, schema modules, context functions, finders, and LiveView management screens.

Rationale: terminology is domain translation data, not an AI-provider detail. It can later be used by DeepL, OpenAI, Google Cloud AI, Ollama, exports, or human translators.

Alternative considered: keep glossary inside the OpenAI plugin. That would make OpenAI the owner of terminology and would force other providers to duplicate or migrate glossary data.

### Provider Plugins Own External AI Calls

Define a provider contract in ExLingo core and implement OpenAI as a provider plugin. A provider receives a normalized suggestion request and returns `{:ok, suggestion_text}` or an error.

Rationale: ExLingo should know what a translation suggestion request is, but should not hard-code external providers. This keeps the OpenAI implementation replaceable by Google Cloud AI, Ollama, or any other provider.

Alternative considered: add OpenAI directly to core. That is simpler for the first implementation but makes provider replacement harder and adds provider dependencies to the core package.

### Suggestion Output Is Plain Translation Text

The provider contract returns only a string containing the translation suggestion. Prompts MUST instruct providers to return only the translation text, with no Markdown, JSON wrapper, confidence, notes, or explanation.

Rationale: the UI only needs a candidate translation. Extra fields cost output tokens and do not support the intended "accept or adapt" workflow.

Alternative considered: structured output with fields such as suggestion, confidence, and notes. This was rejected because confidence is not actionable in the UI and notes are not part of the translator workflow.

### Glossary Resolver Filters Aggressively

Glossary entries are included in provider requests only when all of these are true:

- `source_locale` matches the configured source locale for the request.
- `target_locale` matches the current ExLingo locale.
- `source_term` appears in the source text.
- Optional scopes are either empty or match the current message's domain, context, and application source.

Rationale: unrelated glossary entries waste tokens and can actively degrade translations, especially when translating from English to English or English to Hungarian.

Alternative considered: pass all glossary entries for a target locale. That is easier but increases cost and can bias the model with irrelevant terms.

### Source Text Is `message.msgid`

AI requests use `message.msgid` as the canonical source text. Existing PO text and existing ExLingo translated text can be sent as optional context only when relevant.

Rationale: `msgid` is the stable gettext source. `original_text` is the PO-side text for the target locale and should not be treated as the source sentence to translate.

Alternative considered: use the current PO text as source. That would be wrong for missing or outdated target translations.

### Model Choice Is Configurable

The OpenAI provider exposes a configurable list of allowed models and a default model. The initial default list should prefer low-cost text-capable models such as `gpt-5.4-nano`, `gpt-5.4-mini`, and `gpt-4o-mini`, but applications can override the list.

Rationale: model availability and pricing change over time. Configuration avoids hard-coding a permanent business decision in the UI.

Alternative considered: hard-code a single cheapest model. That lowers UI complexity but prevents controlled quality/cost trade-offs.

### PostgreSQL Is The Supported Storage Target For This Change

The glossary migration is implemented for PostgreSQL only. ExLingo can be pointed at another Ecto repo for a separate database, and PostgreSQL schema isolation is supported through the configured migration/runtime prefix. When a non-`public` prefix is used, the ExLingo migration creates the schema automatically by default.

Rationale: the target deployment only needs PostgreSQL support, while a separate database or schema is useful for isolating ExLingo data from the host application tables.

## Risks / Trade-offs

- Provider APIs change over time -> keep provider-specific code isolated in plugins and keep the core contract stable.
- Automatic suggestions can create hidden token usage -> default to explicit user action unless a project opts into automatic suggestions for missing translations.
- Glossary conflicts can produce ambiguous prompts -> order matching entries by scope specificity and keep usage guidance available for disambiguation.
- Plain text output can include provider chatter -> prompts must require translation text only, and providers should trim surrounding whitespace and reject empty responses.
- Accepting a suggestion could overwrite a valid translation -> only persist after an explicit accept action.

## Migration Plan

1. Add versioned PostgreSQL migration support for glossary entries.
2. Add core glossary schema, context functions, finder/service modules, and tests.
3. Add glossary management UI and navigation.
4. Add provider request/response contract in core.
5. Add AI suggestion form workflow through the plugin integration point.
6. Add the OpenAI provider plugin with configuration validation, model selection, prompt construction, and HTTP integration.
7. Document configuration examples for OpenAI and the provider plugin contract.

Rollback removes the OpenAI plugin from ExLingo configuration and leaves glossary data unused. Database rollback follows the versioned migration down path.

## Open Questions

- Should automatic suggestion generation be available only for empty translations, or should it also support existing translations when a user explicitly asks to improve them?
- Should glossary entries support a strict flag in the first version, or is usage guidance enough for disambiguation?
- Should provider selection be global per ExLingo instance, or should multiple provider plugins be displayed side by side when configured?
