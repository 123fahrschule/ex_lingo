defmodule ExLingo.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_lingo,
      description: "User-friendly translations manager for Elixir/Phoenix projects.",
      package: package(),
      version: "0.5.1",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [
        warnings_as_errors: true
      ],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:uri_query, :logger, :ssl],
      mod: {ExLingo.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:expo, "~> 1.1"},
      {:ecto, "~> 3.13"},
      {:ecto_sql, "~> 3.13"},
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:cognit, github: "123fahrschule/cognit", tag: "0.2.13"},
      {:tailwind, "~> 0.4.1", runtime: Mix.env() == :dev},
      {:jason, "~> 1.4"},
      {:cloak, "~> 1.1"},
      {:cloak_ecto, "~> 1.3"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:sweet_xml, "~> 0.7"},
      {:hackney, "~> 1.20"},
      {:finch, "~> 0.21"},
      {:telemetry, "~> 1.4"},
      {:nebulex, "~> 3.0"},
      {:nebulex_distributed, "~> 3.2"},
      {:nebulex_local, "~> 3.0"},
      {:scrivener, "~> 2.7"},
      {:scrivener_ecto, "~> 3.1"},
      {:uri_query, "~> 0.2.0"},
      # DEV
      {:versioce, "~> 2.0"},
      {:git_cli, "~> 0.3.0"},
      {:esbuild, "~> 0.10.0", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40.2", only: :dev, runtime: false},
      {:gettext, ">= 0.26.0 and < 2.0.0"},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:postgrex, "~> 0.22.2", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:mox, "~> 1.2", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd --cd assets npm install", "assets.build"],
      "assets.build": [
        "esbuild default --minify",
        "tailwind default --minify"
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/123fahrschule/ex_lingo"},
      files: ~w(lib priv dist CHANGELOG.md LICENSE.md mix.exs README.md)
    ]
  end

  defp dialyzer do
    [
      plt_file:
        {:no_warn, ".dialyzer/elixir-#{System.version()}-erlang-otp-#{System.otp_release()}.plt"},
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end

  defp docs do
    [
      extras: ["README.md", "docs/how-to-write-plugins.md", "CHANGELOG.md"],
      groups_for_extras: [
        "ExLingo Guide": ~r/README|how-to-write-plugins/
      ],
      assets: %{"docs/assets" => "assets", "assets/images/readme" => "assets/images/readme"},
      main: "readme"
    ]
  end
end
