# ExLingo Guide
<div align="center">
  <img src="https://github.com/user-attachments/assets/f0352656-397d-4d90-999a-d3adbae1095f">

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
  <a href="https://github.com/123fahrschule/ex_lingo">
    <img src="https://github.com/user-attachments/assets/8839cbec-970b-4fd8-a028-2d9de05a2af6" alt="Logo" height="80">
  </a>
  <br />
  <br />
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
      <li><a href="#detection-of-stale-messages">Detection of stale messages</a></li>
      <li><a href="#translation-progress">Translation progress</a></li>
    </ul>
  </li>
  <li>
    <a href="#plugins">Plugins</a>
    <ul>
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

- Elixir (tested on 1.19.0)
- Phoenix (tested on 1.7.x and 1.8.x with LiveView 1.x)
- Ecto SQL (tested on 3.13)
- PostgreSQL 15+ or SQLite 3.31.0+

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
  repo: MyApp.Repo, # Your app Repo module
  otp_name: :my_app, # Name of your OTP app
  plugins: []
```

Ecto repo module is used mostly for translations persistency. We also need endpoint to use VerifiedRoutes and project_root to locate the project's .po files.

### Database migrations

Migrations is heavily inspired by the Oban approach. To add to the project tables necessary for the operation of ExLingo and responsible for storing translations create migration with:

```bash
mix ecto.gen.migration add_ex_lingo_translations_table
```

Open the generated migration file and set up `up` and `down` functions.

**Current Migration Versions:**
- PostgreSQL: **v4** (adds default context support for Gettext >= `0.26` backend)
- SQLite: **v3** (adds default context support for Gettext >= `0.26` backend)

If you're upgrading from an earlier version of ExLingo, update your migration version to the latest.

#### PostgreSQL

```elixir
defmodule MyApp.Repo.Migrations.AddExLingoTranslationsTable do
  use Ecto.Migration

  def up do
    ExLingo.Migration.up(version: 4, prefix: prefix()) # Prefix is needed if you are using multitenancy with i.e. triplex
  end

  # We specify `version: 1` because we want to rollback all the way down including the first migration.
  def down do
    ExLingo.Migration.down(version: 1, prefix: prefix()) # Prefix is needed if you are using multitenancy with i.e. triplex
  end
end
```

#### SQLite

```elixir
defmodule MyApp.Repo.Migrations.AddExLingoTranslationsTable do
  use Ecto.Migration

  def up do
    ExLingo.Migration.up(version: 3)
  end

  # We specify `version: 1` because we want to rollback all the way down including the first migration.
  def down do
    ExLingo.Migration.down(version: 1)
  end
end
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

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Features

### Extracting from PO files

![Messages](assets/images/readme/messages.png)

ExLingo is based on the Phoenix Framework's default localization tool, GNU gettext. The process, which runs at application startup, analyzes .po files with messages and converts them to a format for convenient use with Ecto and ExLingo itself.

### Storing messages in the database


![Singular translation edit](assets/images/readme/singular.png)

Messages and translations from .po files are stored in tables created by the ExLingo.Migration module. This allows easy viewing and modification of messages from the ExLingo UI or directly from database tools.

With Gettext version >= `0.26`, ExLingo uses a custom backend adapter system (`ExLingo.Backend.Adapter.CachedDB`) that fetches translations from the database/cache at runtime instead of compiled PO files. The caching mechanism prevents constant requests to the database when downloading translations, so you don't have to worry about a delay in application performance.

### Detection of stale messages

![Stale Dashboard Tiles](assets/images/readme/stale-dashboard.png)

ExLingo automatically detects **stale** messages and will help you out with managing them - either `deleting` or `merging` into existing ones.

`Stale messages` are the translations that exist in your database but are no longer present in any locale's PO files. This typically happens during code refactoring when translation keys in the codebase are removed or renamed.

Using fuzzy matching, ExLingo identifies stale but **"mergeable"** messages where stale translations closely resemble active messages.

![Stale messages in Locales view](assets/images/readme/stale-one-by-one.png)

You can take action one by one for every message (delete and/or merge) or you can perform it in bulk (from the Dashboard).

### Translation progress

![Translation progress](assets/images/readme/dashboard.png)

ExLingo tracks the progress of your application's translation into other languages and reports it in the user's dashboard. In the dashboard you can filter your messages by domain or context, or use a search engine. It is also possible to display only the messages that need translation to better see how much work remains to be done.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Plugins

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
