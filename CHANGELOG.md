# Changelog
All notable changes to this project will be documented in this file.

## [1.0.4] - 2026-06-29

### Changed
- Update Hex dependencies to current compatible releases, including Ecto `3.14.0`, Phoenix `1.8.8`, Phoenix LiveView `1.2.3`, Finch `0.23.0`, ExAws `2.7.0`, Hackney `4.4.5`, Nebulex Distributed `3.2.3`, Credo `1.7.19`, ExDoc `0.40.3`, and Tailwind installer `0.5.1`.
- Upgrade the optional Cognit dependency to `0.7.0` for Phoenix LiveView `1.2` compatibility and rebuild distributable JavaScript and CSS assets.
- Keep the CircleCI dependency audit step on valid tasks by running `mix hex.audit` for retired Hex packages and `npm audit --audit-level=high` for assets.

### Fixed
- Add stable IDs to LiveView forms that use form events so LiveView `1.2` form recovery checks no longer emit warnings in tests.
- Adjust inline glossary dropdown actions for the current Cognit dropdown item API.
- Resolve Credo and Dialyzer findings exposed by the dependency update while preserving existing behavior.

## [1.0.3] - 2026-06-16

### Fixed
- Fall back to the original message instead of raising a `FunctionClauseError` when a plural translation exists in the database but its `translated_text` is `nil` (e.g. catalog rows synced for a locale that was never translated). The plural lookup now guards against `nil` the same way the singular lookup does.

## [1.0.2] - 2026-06-09

### Changed
- Upgrade the optional Cognit dependency to `0.5.0` so host applications pinned to the same Cognit release do not need `override: true` to resolve ExLingo.

## [1.0.1] - 2026-06-02

### Changed
- Open the "Add to glossary" quick-capture from the translation editor in the same flyout the glossary section uses, prefilled from the selected text, instead of navigating to a separate page.

### Removed
- Remove the standalone glossary entry form page and its `/glossary/new` and `/glossary/:id` routes; creating and editing glossary entries now always happen in the flyout.

## [1.0.0] - 2026-05-31

### Breaking Changes
- Rename the project identity from Kanta to ExLingo, including OTP app name, package metadata, module namespaces, file paths, migrations, routes, docs, and asset package names.
- Remove non-PostgreSQL storage adapter support. ExLingo now supports PostgreSQL repositories only.
- Remove the application-source concept entirely. Migration v11 drops `ex_lingo_application_sources` and the `application_source_id` columns and narrows the message unique key to `(domain_id, context, msgid)`; this migration is destructive, and its narrowed unique index requires PostgreSQL 15+.

### Added
- Add CircleCI configuration for dependency audits, asset builds, formatting, compilation, Credo, Dialyzer, and test execution with PostgreSQL.
- Add Cognit as the standard UI component library for the ExLingo dashboard.
- Add favicon assets generated from the Cognit brand logo.
- Add core glossary storage and dashboard management UI for approved translation terminology.
- Add AI translation suggestions with a provider plugin contract and an OpenAI provider implementation.
- Add PostgreSQL schema prefix configuration for ExLingo data, including automatic schema creation during ExLingo migrations.
- Add imported PO source references to messages and display message ID, scope, and source positions in the translation form.
- Add an unclear-text review flow so translators can flag vague gettext contexts and developers can review the affected source positions.
- Add a Settings dashboard (`/settings`) backed by a single `ex_lingo_settings` row, with S3 credentials encrypted at rest via Cloak.
- Add fully editable AI prompt templates (global and per-locale, cascading) with documented placeholders surfaced in both the README and the Settings UI, and send translation context to the AI provider.
- Add configurable translation-quality validation thresholds (length ratio, placeholder, punctuation) cascading database → config → default.
- Add a configurable S3 folder prefix so one bucket can be shared across services.
- Add S3-backed context image uploads for messages (browser presigned upload, thumbnails, deletion, and lifecycle cleanup on merge/delete).
- Add PO export from the database to `.po` files, with in-place overwrite via the File System Access API and a ZIP download fallback.
- Add an `msgid_plural` column captured on import and used during export.
- Add possible-duplicate detection with confidence scoring and a dashboard summary.
- Add inline translation editing with keyboard shortcuts, save indicators, quick glossary capture from selected text, and inline quality warnings.

### Changed
- Rework the dashboard, translation tables, filters, forms, tabs, pagination, and app shell to use Cognit components, typography, tokens, and icons.
- Add a compact ExLingo dashboard density layer so Cognit spacing and typography fit embedded host applications.
- Replace the custom ExLingo sidebar logo with the Cognit app-side-nav branding used by Absence.
- Raise the minimum Elixir version to `~> 1.18` to match Cognit's runtime requirement.
- Seed editable ExLingo translations from existing PO-file translations on import without overwriting existing database edits.
- Update Hex dependencies to current compatible releases, including Phoenix, Phoenix LiveView, Ecto, Gettext, Nebulex, ExDoc, and Postgrex.
- Update npm dependencies to resolve audit findings, including Alpine.js, Babel, Autoprefixer, PostCSS, Tailwind CSS 3.4.19, and transitive lockfile updates.
- Update README badges and project links for the independent ExLingo repository and CircleCI workflow.
- Document dedicated ExLingo repos, PostgreSQL schema prefix setup, and AI provider configuration in README/plugin docs.
- Update license attribution for the independent ExLingo development line.
- Relax the Gettext dependency constraint to support host applications on Gettext `0.26.x` and `1.x`.
- Rebuild distributable JavaScript and CSS assets with the updated dependency set.
- Treat gettext context as message metadata instead of a managed dashboard entity; context remains visible during translation and searchable with message text.
- Upgrade Cognit to `0.2.24` (namespaced `Cognit.*` LiveView hooks) and depend on it optionally so host applications can bump Cognit independently.
- Make the dashboard locale switch follow Cognit's shared `app_locale` cookie convention instead of a parallel `?locale=` mechanism, while still honouring the host's locale handoff.
- Persist the sidebar collapsed/expanded state across reloads and navigation.

### Fixed
- Update Nebulex cache configuration for the current adapter packages.
- Replace `length/1` emptiness checks that caused Credo warnings in the new CI pipeline.
- Keep ExLingo PostgreSQL migration primary keys independent from host application migration defaults.
- Avoid falling back to the public schema for message lookups when the public ExLingo tables do not exist.
- Serve dashboard font assets from ExLingo so Cognit typography and Material Symbols icons work in host applications.

### Removed
- Remove the legacy ExLingo logo component and old logo image artifacts.
- Remove historical non-PostgreSQL migration modules and adapter branches.
- Remove managed context tables, context CRUD screens, context filters, and glossary context scoping.
- Remove GitHub Actions, GitHub issue and pull request templates, Lefthook configuration, commitlint hook, Code of Conduct, and Contributing guide from the forked project.
- Remove the obsolete `@tailwindcss/forms` npm dependency after switching to the Cognit Tailwind preset.

### Security
- Resolve npm audit findings previously reported as 11 vulnerabilities.
- Verify Hex dependencies with `mix deps.audit`.

## [0.5.1] - 2025-11-12
### Fixed
- Fix bug when context is nil in PO file (#134)

## [0.5.0] - 2025-11-03

### Breaking Changes
- **Gettext 1.0.0 Migration**: This version requires updating your Gettext module definition to use the new backend adapter system. You must define `use ExLingo.Gettext.Backend` in your Gettext module and configure the adapter.

### Added
- Gettext versions v0.26 and v1.0.0 compatibility with via custom backend adapter system
- Allow custom locales (i.e. "`es-es`") (#100)
- Stale messages detection and merging (#120)
- Updated Tailwind to v3.4.17 (#130)

### Changed (Dependencies)
- Gettext supported versions updated to 0.26 and 1.x
- Phoenix relaxed to ~> 1.7 (allowing minor version bumps)
- Phoenix LiveView relaxed to >= 0.20.0 (allowing for 1.x versions)
- `shards` dependency dropped
- `expo` relaxed to >= 0.3.0
- `scrivener_ecto` upgraded to ~> 3.0

## [0.4.2] - 2025-08-25
### Fixed
- Dialyzer errors related to Phoenix version detection (#122)
- Replace Mix.Dep.Lock.read/0 with Application.spec/2 for better static analysis compatibility
- .dialyzer_ignore.exs to handle Phoenix dependency warnings

### Added
- Phoenix 1.8 and Phoenix LiveView 1.x compatibility (#122)

Authored by: Jakub Lambrych <jakub.lambrych@curiosum.com>
Signed-off-by: Michał Buszkiewicz <michal@curiosum.com>

## [0.4.1] - 2024-10-09

### Added
- Expand ExLingo.Query module (#86)
- Button for manual cache clearing (#85)
- Application source support
- Support for multiline msgids (#56)
- Support for nested scopes and different main path (#61)
- Support for different ID types (#52)
- Way to create new application source
- Way to clear all filters at once
- `dashboard_path` helper to verified routes
- `Colors` module
- Chevrons to `Icons` module
- Missing @moduledoc
- Versioce for version bumping
- Doc to `compiling?` function
- Child LV dashboard components support (#42)
- Docs to DashboardLive

### Changed
- Improve UX when editing many translations (#62)
- Improve filter bar UI (#84)
- Make filters bar responsive
- Improve readability of `Router`
- Improve CI (#80)
- Improve UX when using filters (#49)
- Improve efficiency of messages list query
- Refactor translations_live.ex
- Update pagination.ex
- Replace `parse_msgid/1` with just `Enum.join`
- Extract logic of `parse_filters/1`s reduce to `parse_filter/2`
- Support for newer phoenix_html 4 with phoenix_html_helpers (#47)
- Support translations during compilation (#48)
- Search for PO files only in priv/gettext (#41)
- PO Extractor - allow to import multi-lines msgstr (#40)

### Fixed
- Pagination logic for not showing many pages (#71)
- Translation preloads to preload only necessary data (#60)
- `application_source_form_live`
- Migrations
- Pagination failing to parse int (#44)
- Credo issues
- Naming across file

### Changed (Dependencies)
- Bump ecto versions
- Bump uri_query version
- Bump credo and dialyxir versions
- Use Ubuntu 24.04 LTS in CI
- Add supported Elixir versions
- Remove unsupported OTP version

### Changed (Configuration)
- Restore params after saving a translation
- Recover filters from params on mount in the translations list (#49)
- Properly find index in Select
- Parse params and add redirects
- Return error when `id_parse_function` provided with MFA with invalid arity
- Suppress warning about router.ex
- Changes to make import export plugin work

### Removed
- Remove devenv (#77)
- Remove autogenerated dummy test
- Remove Logger

Co-authored-by: Jakub Melkowski <9402720+Blatts12@users.noreply.github.com>
Co-authored-by: Maksymilian Jodłowski <maksymilian.jodlowski@gmail.com>
Co-authored-by: Jan Świątek <jan.swiatek@curiosum.com>

Signed-off-by: Jan Jakůbek <jan.jakubek96@gmail.com>

## [0.3.1] - 2023-10-13

### Added
- API endpoints (#36)
- Optional API authorization
- @moduledoc to APIAuthPlug
- API scaffolding

### Fixed
- Minor naming issues

## [0.3.0] - 2023-09-26

### Changed
- Update phoenix_live_view to 0.20
- Update ExLingo version to 0.3.0
- Improve translations search (#21)
- Improve efficiency of messages list query
- Require opts keyword list in join_resource/3

### Fixed
- JS error on LiveView page change (#34)
- README missing import in router (#32)

### Deprecated
- Get rid of deprecated live_component/2

## [0.2.2] - 2023-09-05

### Changed
- Update information about POWriter (#29)
- Add badges (#27)

## [0.2.1] - 2023-09-04

### Changed
- Add badges (#28)
- Update README to match ExLingo version (#26)

## [0.2.0] - 2023-09-04

### Added
- Dialyzer (#18)
- Plugin docs, specs and conditional components rendering (#18)

### Changed
- Set docs entry and bump mix version (#24)
- Update "How to write plugins?" tutorial (#18)
- Update gettext repo (#22)
- Update demo link in README (#20)
- Module names consistency, explicit ArgumentError rescue (#18)

### Fixed
- Improve UI and plural translations form (#23)
- Use truncate CSS prop instead of String.slice
- Credo and dialyzer warnings (#18)
- Wrong type (it was a Map all along)
- Multitenancy projects issues (#14)
- Down migration order (#14)
- prefix() calls into prefix (#14)
- Phoenix VerifiedRoutes issues & missing views (#10)
- ExLingo in mix release projects (#8)

### Changed
- Fallback to public prefix for messages (#14)
- Pass on_mount option to live_session opts (#14)
- Use https instead ssh connection for gettext (#14)
- Pass down opts to respective up&down migrations (#14)
- Add limit 1 (#14)
- Rework plural messages handling (#14)
- Change unverified url to unverified path (#11)
- Extract DeepL plugin to external package (#12)

### Added
- Devenv (#14)

## [0.1.0] - 2023-05-18

Initial version of ExLingo translations manager.

### Added
- Basic rwd (responsive web design)
- Dark mode
- Messages filters
- Plugins management
- Gettext contexts
- Form for plural translation updates
- Form for singular translation updates
- Plural translations
- Nebulex as a caching tool
- Sample pages in petal
- Basic configuration for semi-PETAL stack
- PopulateCacheWithStoredDataService
- File structure

### Changed
- Update readme
- Update package version
- Update deps & readme
- Rework translation listings
- Change translations to singular translations
- Mimic LiveDashboard mechanism in ExLingo (#3)
- Adjust gettext repo for plural messages handling
- Mainly UI adjusts
- Small refactoring

### Fixed
- Github dependency on gettext fork (#6, #1)
- Plural translations
- Cached translations in UI (#4)
- LV redirect loop
- Paths resolution
