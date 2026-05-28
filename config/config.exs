import Config

config :ex_lingo, ExLingo.Cache,
  primary: [
    gc_interval: :timer.hours(24),
    backend: :ets
  ]

config :phoenix, :json_library, Jason
config :phoenix, :stacktrace_depth, 20

config :logger, level: :warning
config :logger, :console, format: "[$level] $message\n"

if config_env() == :dev do
  config :esbuild,
    version: "0.14.41",
    default: [
      args: ~w(js/app.js --bundle --target=es2020 --outdir=../dist/js),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]

  config :tailwind,
    version: "3.4.19",
    default: [
      args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../dist/css/app.css
    ),
      cd: Path.expand("../assets", __DIR__)
    ]

  config :versioce, :changelog,
    datagrabber: Versioce.Changelog.DataGrabber.Git,
    formatter: Versioce.Changelog.Formatter.Keepachangelog

  config :versioce,
    files: [
      "README.md",
      "CHANGELOG.md",
      "mix.exs",
      "assets/package.json",
      "package.json"
    ],
    post_hooks: [
      Versioce.PostHooks.Changelog,
      Versioce.PostHooks.Git.Release
    ]

  config :versioce, :git,
    commit_message_template: "chore: :bookmark: Bump version to {version}",
    tag_template: "v{version}",
    tag_message_template: "Release v{version}"
end

if config_env() == :test do
  config :ex_lingo,
    ecto_repos: [ExLingo.Test.Repo]

  config :ex_lingo, ExLingo.Test.Repo,
    username: System.get_env("POSTGRES_USERNAME", "postgres"),
    password: System.get_env("POSTGRES_PASSWORD", "postgres"),
    hostname: System.get_env("POSTGRES_HOSTNAME", "localhost"),
    database: "ex_lingo_test",
    port: 5432,
    pool: Ecto.Adapters.SQL.Sandbox,
    pool_size: 10

  config :ex_lingo, ExLingo.Test.Endpoint,
    secret_key_base:
      "test_secret_key_base_test_secret_key_base_test_secret_key_base_test_secret_key_base",
    live_view: [signing_salt: "ex-lingo-test-salt"],
    server: false
end
