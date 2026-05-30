# ExLingo Guide

<div align="center">
  <h1>ExLingo</h1>
  <p><strong>User-friendly translations manager for Elixir/Phoenix projects</strong></p>

<p>
  <a href="https://github.com/123fahrschule/ex_lingo/blob/main/LICENSE.md">
    <img src="https://img.shields.io/badge/License-MIT-1D0642?style=for-the-badge&logo=open-source-initiative&logoColor=white&labelColor=1D0642" alt="License: MIT">
  </a>
</p>
</div>

<br />

## About The Project

<div align="left">
  <p style="margin-top: 3rem; font-size: 14pt;" align="left">
    <a href="https://github.com/123fahrschule/ex_lingo/issues">Report Bug</a>
    ·
    <a href="https://github.com/123fahrschule/ex_lingo/issues">Request Feature</a>
  </p>
</div>

If you're working on an Elixir/Phoenix project and need to manage translations, you know how time-consuming and error-prone it can be. That's where ExLingo comes in. Our tool simplifies the process of managing translations by providing an intuitive interface for adding, editing, and deleting translations. Our tool also makes it easy to keep translations up-to-date as your project evolves. With ExLingo, you can streamline your workflow and focus on building great software, not managing translations.

<div>
  <a href="https://dl.circleci.com/status-badge/redirect/gh/123fahrschule/ex_lingo/tree/main">
    <img alt="CI Status" src="https://dl.circleci.com/status-badge/img/gh/123fahrschule/ex_lingo/tree/main.svg?style=svg">
  </a>
  <a href="https://hex.pm/packages/ex_lingo">
    <img alt="Hex Version" src="https://img.shields.io/hexpm/v/ex_lingo.svg">
  </a>
  <a href="https://hexdocs.pm/ex_lingo">
    <img alt="Hex Docs" src="http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat">
  </a>
</div>

<br/>

## Table of contents

<ul style="margin-top: 3rem; margin-bottom: 3rem;">
  <li>
    <a href="#about-the-project">About The Project</a>
  </li>
  <li>
    <a href="#getting-started">Getting Started</a>
    <ul>
      <li><a href="#prerequisites">Prerequisites</a></li>
      <li><a href="#installation">Installation</a></li>
      <li><a href="#upgrading-from-ex_lingo-04">Upgrading from ExLingo 0.4</a></li>
      <li><a href="#configuration">Configuration</a></li>
      <li><a href="#database-migrations">Database Migrations</a></li>
      <li><a href="#gettext-module">Gettext Module</a></li>
      <li><a href="#ex_lingo-supervisor">ExLingo Supervisor</a></li>
      <li><a href="#ex_lingo-ui">ExLingo UI</a></li>
    </ul>
  </li>
  <li>
    <a href="#features">Features</a>
    <ul>
      <li><a href="#extracting-from-po-files">Extracting from PO files</a></li>
      <li><a href="#storing-messages-in-the-database">Storing messages in the database</a></li>
      <li><a href="#translation-glossary">Translation glossary</a></li>
      <li><a href="#ai-translation-suggestions">AI translation suggestions</a></li>
      <li>
        <a href="#settings">Settings</a>
        <ul>
          <li><a href="#setting-up-an-s3-bucket">Setting up an S3 bucket</a></li>
        </ul>
      </li>
      <li><a href="#detection-of-stale-messages">Detection of stale messages</a></li>
      <li><a href="#translation-progress">Translation progress</a></li>
    </ul>
  </li>
  <li>
    <a href="#plugins">Plugins</a>
    <ul>
      <li><a href="#ai-translation-suggestions-plugin">AI translation suggestions</a></li>
      <li><a href="#po-writer">PO Writer</a></li>
      <li><a href="#deepl">DeepL</a></li>
      <li><a href="#ex_lingosync">Translation synchronization</a></li>
    </ul>
  </li>
  <li><a href="#roadmap">Roadmap</a></li>
  <li>
    <a href="#development">Development</a>
    <ul>
      <li><a href="#running-tests">Running Tests</a></li>
    </ul>
  </li>
  <li><a href="#community">Community</a></li>
  <li><a href="#license">License</a></li>
  <li><a href="#contact">Contact</a></li>
</ul>

---

_Note: Official documentation for ExLingo library is [available on hexdocs][hexdoc]._

[hexdoc]: https://hexdocs.pm/ex_lingo

---

<br />

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Getting Started

### Prerequisites

- Elixir 1.18+ (tested on 1.19.0)
- Phoenix (tested on 1.7.x and 1.8.x with LiveView 1.x)
- Ecto SQL (tested on 3.13)
- PostgreSQL 15+

### Installation

The package can be installed
by adding `ex_lingo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_lingo, "~> 0.5.1"},
  ]
end
```

### Upgrading from ExLingo 0.4

Thankfully we are getting rid of the prior solution revolving around a custom Gettext fork and right now ExLingo is fully compatible with Gettext 0.26 and 1.x.

If you're upgrading from ExLingo 0.4 to 0.5, you need to update your Gettext module definition to use the new backend adapter system. You must define `use ExLingo.Backend` in your Gettext module and configure the adapter.

```elixir
defmodule MyAppWeb.Gettext do
  # ExLingo >= 0.5
  use ExLingo.Backend, otp_app: :my_app

  # ExLingo <= 0.4 or vanilla Gettext
  use Gettext, otp_app: :my_app, repo: MyApp.Repo
end
```

Inside your `[my_app]_web.ex` file:

```elixir
defmodule MyAppWeb do
  defp html_helpers do
    quote do
      # ExLingo >= 0.5 or vanilla Gettext
      use Gettext, backend: MyAppWeb.Gettext

      # ExLingo <= 0.4
      import MyAppWeb.Gettext
    end
  end
end
```

### Configuration

Add to `config/config.exs` file:

```elixir
# config/config.exs
config :my_app, ExLingo,
  endpoint: MyAppWeb.Endpoint, # Your app Endpoint module
  repo: MyApp.Repo, # Your app Repo module, or a dedicated ExLingo repo
  otp_name: :my_app, # Name of your OTP app
  prefix: nil, # Optional PostgreSQL schema, e.g. "ex_lingo"
  plugins: []
```

Ecto repo module is used mostly for translations persistency. We also need endpoint to use VerifiedRoutes and project_root to locate the project's .po files.

ExLingo encrypts sensitive settings (e.g. the S3 secret access key) at rest. Set a strong, stable encryption secret in production:

```elixir
# config/runtime.exs
config :ex_lingo, :settings_encryption_key, System.fetch_env!("EX_LINGO_SETTINGS_KEY")
```

The value is hashed (SHA-256) into the AES-256-GCM key used by `ExLingo.Vault`. If it is not configured, a built-in fallback is used so development and tests work out of the box — do not rely on the fallback in production, and note that changing the secret makes previously encrypted values unreadable.

You can store ExLingo data in another database by configuring `repo:` with a dedicated Ecto repo, for example `MyApp.ExLingoRepo`. You can also store ExLingo tables in a PostgreSQL schema by setting `prefix: "ex_lingo"` and running the ExLingo migration with the same prefix. When a non-`public` prefix is used, ExLingo creates the PostgreSQL schema automatically during its migration by default.

### Database migrations

Migrations is heavily inspired by the Oban approach. To add to the project tables necessary for the operation of ExLingo and responsible for storing translations create migration with:

```bash
mix ecto.gen.migration add_ex_lingo_translations_table
```

Open the generated migration file and set up `up` and `down` functions.

**Current Migration Versions:**

- PostgreSQL: **v8** (adds the `ex_lingo_settings` table for configurable AI prompts and S3 storage)

If you're upgrading from an earlier version of ExLingo, update your migration version to the latest.

#### PostgreSQL

```elixir
defmodule MyApp.Repo.Migrations.AddExLingoTranslationsTable do
  use Ecto.Migration

  def up do
    ExLingo.Migration.up(version: 8)
  end

  # We specify `version: 1` because we want to rollback all the way down including the first migration.
  def down do
    ExLingo.Migration.down(version: 1)
  end
end
```

#### PostgreSQL schema

To use a dedicated PostgreSQL schema, pass the same prefix to the migration and ExLingo runtime configuration. The migration runs `CREATE SCHEMA IF NOT EXISTS` automatically, so the host application does not need a separate migration just to create the schema.

```elixir
# migration
def up, do: ExLingo.Migration.up(version: 8, prefix: "ex_lingo")
def down, do: ExLingo.Migration.down(version: 1, prefix: "ex_lingo")

# config/config.exs
config :my_app, ExLingo,
  endpoint: MyAppWeb.Endpoint,
  repo: MyApp.Repo,
  otp_name: :my_app,
  prefix: "ex_lingo",
  plugins: []
```

If your database user is not allowed to create schemas and the schema is managed externally, disable automatic schema creation explicitly:

```elixir
def up, do: ExLingo.Migration.up(version: 8, prefix: "ex_lingo", create_schema: false)
```

After that run:

```bash
mix ecto.migrate
```

### Gettext module

Configuring Gettext requires just a single change to use `ExLingo.Backend`:

```elixir
defmodule MyAppWeb.Gettext do
  use ExLingo.Backend, otp_app: :my_app
end
```

If you're using a Gettext version < `0.26`, refer to the [official documentation](https://github.com/elixir-gettext/gettext) for migration instructions.

### Using Gettext in the application

Using gettext across the app does not differ from the regular `Gettext` usage:

```elixir
defmodule MyAppWeb.CustomComponent do
  use Gettext, backend: MyAppWeb.Gettext

  def render(assigns) do
    ~H"""
    {gettext("Actions")}
    """
  end
end
```

### ExLingo Supervisor

In the `application.ex` file of our project, we add ExLingo and its configuration to the list of processes.

```elixir
  def start(_type, _args) do
    children = [
      ...
      {ExLingo, Application.fetch_env!(:my_app, ExLingo)}
      ...
    ]
    ...
  end
```

### ExLingo UI

Inside your `router.ex` file we need to connect the ExLingo panel using the ex_lingo_dashboard macro.

```elixir
import ExLingoWeb.Router

scope "/" do
  pipe_through :browser

  ex_lingo_dashboard("/ex_lingo")
end
```

The dashboard serves its own compiled CSS, JavaScript, favicon, and font assets
from the mounted dashboard path. Host applications do not need to add ExLingo
templates to their Tailwind `content` list; mounting the router macro is enough.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Features

### Extracting from PO files

![Messages](assets/images/readme/messages.png)

ExLingo is based on the Phoenix Framework's default localization tool, GNU gettext. The process, which runs at application startup, analyzes .po files with messages and converts them to a format for convenient use with Ecto and ExLingo itself.

When PO files contain existing `msgstr` translations, ExLingo seeds the editable
database translation from that value on first import. Existing ExLingo edits are
kept and are not overwritten by later PO-file scans.

### Storing messages in the database

![Singular translation edit](assets/images/readme/singular.png)

Messages and translations from .po files are stored in tables created by the ExLingo.Migration module. This allows easy viewing and modification of messages from the ExLingo UI or directly from database tools.

With Gettext version >= `0.26`, ExLingo uses a custom backend adapter system (`ExLingo.Backend.Adapter.CachedDB`) that fetches translations from the database/cache at runtime instead of compiled PO files. The caching mechanism prevents constant requests to the database when downloading translations, so you don't have to worry about a delay in application performance.

### Translation glossary

ExLingo can store approved terminology in `ex_lingo_glossary_entries`. Each glossary entry defines a source locale, target locale, source term, target term, optional usage guidance, and optional scope by domain or application source.

The glossary is core translation data. Provider plugins can use it, but the terminology is not tied to a specific AI provider.

### AI translation suggestions

AI translation suggestions can be added to the translation edit screen through plugins. The user-facing result is intentionally only the suggested translation text. ExLingo does not ask providers for confidence scores, notes, rationale, or alternatives.

When a suggestion is requested, ExLingo matches only glossary entries that apply to the current source locale, target locale, source text, and optional message scope. Irrelevant glossary entries are not sent to the provider.

### Settings

The dashboard includes a `/settings` page (linked at the bottom of the sidebar) backed by a single row in `ex_lingo_settings`.

- **AI translation prompt** — a single, fully editable prompt template (global plus optional per-locale overrides) that is the complete text sent to the AI for each suggestion. The template uses `{{placeholders}}` (see below) that are replaced per request, so everything the model receives is visible and controllable in one place — no hidden, hardcoded message. When a suggestion is requested the template is resolved by cascading: per-locale override → global template → a built-in default. The row is created lazily on first access and seeded with the built-in template, so upgrading loses nothing. It is cached to avoid a database round-trip on every request and invalidated on save.

  **Available placeholders** (also shown in a reference box on the settings page):

  | Placeholder | Sent value |
  | --- | --- |
  | `{{source_text}}` | the text to translate — **required** |
  | `{{target_locale}}` | target locale code, e.g. `de` — **required** |
  | `{{source_locale}}` | source locale code, e.g. `en` |
  | `{{target_locale_name}}` | human-readable target language name |
  | `{{context}}` | the message's gettext context / disambiguation note |
  | `{{message_type}}` | `singular` or `plural` |
  | `{{current_translation}}` | the existing translation to improve, if any |
  | `{{glossary}}` | matching glossary terms for this request |
  | `{{plural_form_index}}` | plural form index (plural messages) |
  | `{{plural_examples}}` | example quantities for the plural form |

  The two **required** placeholders are always sent to the model even if you remove them from the template — ExLingo appends them automatically so a request is never missing the text to translate or its target locale. Empty optional values render as `(none)`.

- **S3 storage** — credentials used for image-based translation context (wired up in a later release), plus a configurable folder prefix so a single bucket can be shared across services with each one writing into its own subfolder (defaults to the bucket root `/`). The secret access key is encrypted at rest with [Cloak](https://hex.pm/packages/cloak_ecto) (AES-256-GCM) through `ExLingo.Vault`; it is decrypted transparently on load and is never rendered back into forms. The encryption key is derived from `config :ex_lingo, :settings_encryption_key`, which host applications should set to a strong, stable secret (a built-in fallback keeps dev/test working). Secrets are never stored in plaintext.

See [Setting up an S3 bucket](#setting-up-an-s3-bucket) for how to provision the bucket, user, and permissions.

#### Setting up an S3 bucket

ExLingo stores screenshots (used as extra translation context) in an Amazon S3 bucket. You can dedicate a bucket to ExLingo, or share one bucket across several services and keep ExLingo's files in their own subfolder via the **Folder prefix** setting. The steps below use the AWS Console; the AWS CLI works just as well.

**1. Create the bucket**

1. Open the [S3 console](https://s3.console.aws.amazon.com/s3/) → **Create bucket**.
2. Pick a globally unique **Bucket name** (e.g. `my-company-assets`) and a **Region** (e.g. `eu-central-1`). Note both — you enter them in ExLingo's settings.
3. Leave **Block all public access** enabled. ExLingo accesses the bucket with credentials, not public URLs.
4. Create the bucket. If you share it across services, decide on a subfolder for ExLingo now (e.g. `ex_lingo/`) and put it in the **Folder prefix** field.

**2. Create an IAM user for ExLingo**

1. Open the [IAM console](https://console.aws.amazon.com/iam/) → **Users** → **Create user**.
2. Name it (e.g. `ex-lingo-s3`) and do **not** grant console access — it only needs programmatic access.
3. On the permissions step choose **Attach policies directly** → **Create inline policy** → the **JSON** tab, and paste the policy below.

**3. Inline policy (least privilege)**

Paste this, then replace **both** occurrences of `YOUR_BUCKET_NAME` with your bucket name. It grants read/write/delete on objects and listing on the bucket — nothing else.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ExLingoObjectAccess",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/*"
    },
    {
      "Sid": "ExLingoListBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME"
    }
  ]
}
```

If you share the bucket and want to restrict ExLingo strictly to its subfolder, scope the object statement's resource to the prefix (e.g. `arn:aws:s3:::YOUR_BUCKET_NAME/ex_lingo/*`) and add a `Condition` with `s3:prefix` to the `ListBucket` statement.

**4. Get the credentials**

1. After creating the user, open it → **Security credentials** → **Create access key** → use case **Application running outside AWS**.
2. Copy the **Access key ID** and **Secret access key**. The secret is shown only once — store it safely.

**5. Enter them in ExLingo**

Open **Settings → S3 storage** in the dashboard and fill in:

| Field             | Value                                                                    |
| ----------------- | ------------------------------------------------------------------------ |
| Access key ID     | the access key ID from step 4                                            |
| Secret access key | the secret access key from step 4 (write-only; stored encrypted)         |
| Bucket            | the bucket name from step 1                                              |
| Region            | the bucket's region, e.g. `eu-central-1`                                 |
| Folder prefix     | subfolder for this service, e.g. `ex_lingo/`, or `/` for the bucket root |

Save your settings. A **Test connection** button is available and will verify bucket access once image uploads are wired up.

### Detection of stale messages

![Stale Dashboard Tiles](assets/images/readme/stale-dashboard.png)

ExLingo automatically detects **stale** messages and will help you out with managing them - either `deleting` or `merging` into existing ones.

`Stale messages` are the translations that exist in your database but are no longer present in any locale's PO files. This typically happens during code refactoring when translation keys in the codebase are removed or renamed.

Using fuzzy matching, ExLingo identifies stale but **"mergeable"** messages where stale translations closely resemble active messages.

![Stale messages in Locales view](assets/images/readme/stale-one-by-one.png)

You can take action one by one for every message (delete and/or merge) or you can perform it in bulk (from the Dashboard).

### Translation progress

![Translation progress](assets/images/readme/dashboard.png)

ExLingo tracks the progress of your application's translation into other languages and reports it in the user's dashboard. In the dashboard you can filter your messages by domain or use a search engine that also considers gettext context text. It is also possible to display only the messages that need translation to better see how much work remains to be done.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Plugins

### AI translation suggestions plugin

AI translation suggestions use two plugin roles:

- `ExLingo.AI.Translations.Plugin` adds the UI to the translation edit form.
- A provider plugin, such as `ExLingo.AI.Providers.OpenAI`, performs the external API request.

Configure the source locale once for the UI plugin and configure provider credentials and models on the provider plugin:

```elixir
# config/config.exs
config :my_app, ExLingo,
  endpoint: MyAppWeb.Endpoint,
  repo: MyApp.Repo,
  otp_name: :my_app,
  plugins: [
    {ExLingo.AI.Translations.Plugin, source_locale: "en"},
    {ExLingo.AI.Providers.OpenAI,
     api_key: {:system, "OPENAI_API_KEY"},
     allowed_models: ["gpt-5.4-nano", "gpt-5.4-mini", "gpt-4o-mini"],
     default_model: "gpt-5.4-nano"}
  ]
```

`OPENAI_API_KEY` is read from the environment by default. You can also override the endpoint for tests, proxies, or compatible gateways:

```elixir
{ExLingo.AI.Providers.OpenAI,
 api_key: {:system, "OPENAI_API_KEY"},
 endpoint: "https://api.openai.com/v1/responses",
 allowed_models: ["gpt-5.4-nano", "gpt-5.4-mini"],
 default_model: "gpt-5.4-nano"}
```

Future providers can use the same provider contract by implementing `ExLingo.AI.Translations.Provider` and returning `{:ok, suggestion_text}` or `{:error, reason}` from `suggest_translation/1`.

### DeepL

Not all of us are polyglots, and sometimes we need the help of machine translation tools. For this reason, we have provided plug-ins for communication with external services that will allow you to translate texts into another language without knowing it. As a first step, we introduced integration with DeepL API offering 500,000 characters/month for free and more in paid plans. To use DeepL API add `{:ex_lingo_deep_l_plugin, "~> 0.1.1"}` to your `deps` and append `ExLingo.DeepL.Plugin` to the list of plugins along with the API key from your account at DeepL. New features will then be added to the ExLingo UI that will allow you to translate using this tool.

![Plural](assets/images/readme/plural.png)

```elixir
# mix.exs
defp deps do
  ...
  {:ex_lingo_deep_l_plugin, "~> 0.1.1"}
end
```

```elixir
# config/config.exs
config :ex_lingo,
  ...
  plugins: [
    {ExLingo.DeepL.Plugin, api_key: "YOUR_DEEPL_API_KEY"}
  ]
```

### ExLingoSync

The ExLingoSync plugin allows you to synchronize translations between your production and staging/dev environments. It ensures that any changes made to translations in one are reflected in the others, helping you maintain consistency across different stages of development.

```elixir
# mix.exs
defp deps do
  ...
  {:ex_lingo_sync_plugin, "~> 0.1.0"}
end
```

You need to have ExLingo API configured by using ex_lingo_api macro.

```elixir
# router.ex
import ExLingoWeb.Router

scope "/" do
  ex_lingo_api("/ex_lingo-api")
end
```

#### Authorization

Set `EX_LINGO_SECRET_TOKEN` environment variable for restricting API access. It should be generated with `mix phx.gen.secret 256` and both environments must have the same `EX_LINGO_SECRET_TOKEN` environment variables.

You can also disable default authorization mechanism and use your own, by passing `disable_api_authorization: true` option into ExLingo's config.

### PO Writer

ExLingo was created to allow easy management of static text translations in the application, however, for various reasons like wanting a backup or parallel use of other tools like TMS etc. you may want to overwrite .po files with translations entered in ExLingo. To install it append `{:ex_lingo_po_writer_plugin, "~> 0.1.0"}` to your `deps` list. Then add `ExLingo.Plugins.POWriter` to the list of plugins, and new functions will appear in the ExLingo UI to allow writing to .po files.

```elixir
# mix.exs
defp deps
  ...
  {:ex_lingo_po_writer_plugin, "~> 0.1.0"},
end
```

```elixir
# config/config.exs
config :ex_lingo,
  ...
  plugins: [
    ExLingo.POWriter.Plugin
  ]
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Roadmap

- [ ] Typespecs, tests, better docs
- [x] CI/CD
- [ ] Gettext extract/merge automation
- [ ] Google Translate, Yandex Translate, LibreTranslate Plugins
- [ ] File import/export
- [ ] Bumblebee AI translations
- [ ] REST API

See the [open issues](https://github.com/123fahrschule/ex_lingo/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Development

### Running Tests

If you're contributing to ExLingo development, you'll need to run the test suite. The tests require a PostgreSQL database.

#### Prerequisites for Development

- PostgreSQL 15+ (for running tests)
- All prerequisites listed in [Getting Started](#prerequisites)

#### Test Setup

First-time setup (or if tests are failing due to database issues):

```bash
# Setup test database and run migrations
MIX_ENV=test mix ecto.drop && MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate
```

<!-- LICENSE -->

### Community

- **Issues**: [GitHub Issues](https://github.com/123fahrschule/ex_lingo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/123fahrschule/ex_lingo/discussions)

### License

Distributed under the MIT License. See `LICENSE.md` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

### Contact

Use [GitHub Issues](https://github.com/123fahrschule/ex_lingo/issues) for bug reports and feature requests, and [GitHub Discussions](https://github.com/123fahrschule/ex_lingo/discussions) for general questions.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
