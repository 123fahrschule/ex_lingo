defmodule ExLingo.MigrationVersionChecker do
  @moduledoc """
  GenServer responsible for checking if a new migration version is available for ExLingo.

  This module runs a version check when started to compare the current database migration
  version against the latest available version. If a newer version is available, it displays
  a formatted warning message in the console with:

  - Current and latest version numbers
  - Step-by-step instructions for updating
  - Commands to generate and run the required migrations

  The checker supports PostgreSQL databases.
  """

  use GenServer
  require Logger

  @colors [
    warning: :yellow,
    highlight: :cyan,
    brand: :magenta,
    reset: :reset
  ]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    safely_check_version()

    {:ok, %{}}
  end

  defp safely_check_version do
    check_version()
  rescue
    exception ->
      Logger.error(Exception.format(:error, exception, __STACKTRACE__))
  catch
    kind, reason ->
      Logger.error(Exception.format(kind, reason, __STACKTRACE__))
  end

  defp check_version do
    migrator = ExLingo.Migrations.Postgresql
    latest_version = migrator.current_version()

    migrated =
      migrator.migrated_version(%{
        repo: ExLingo.Repo.get_repo(),
        prefix: ExLingo.Repo.configured_prefix() || "public"
      })

    if migrated < latest_version do
      warning_message = """
      #{colorize("⚠️  [ExLingo Migration Alert]", @colors[:warning])}
      #{colorize("━━━━━━━━━━━━━━━━━━━━━━━━━━", @colors[:brand])}

      A new version of ExLingo migrations is available for your database!

      Current version: #{colorize(to_string(migrated), @colors[:highlight])}
      Latest version: #{colorize(to_string(latest_version), @colors[:highlight])}

      To ensure optimal performance and functionality, please update your database schema.

      📝 Here's what you need to do:

      1. Generate a new migration:
         #{colorize("$ mix ecto.gen.migration update_ex_lingo_migrations", @colors[:brand])}

      2. Add the following to your migration file:
         #{colorize("def up do", @colors[:highlight])}
           #{colorize("ExLingo.Migration.up(version: #{latest_version})", @colors[:highlight])}
         #{colorize("end", @colors[:highlight])}

         #{colorize("def down do", @colors[:highlight])}
           #{colorize("ExLingo.Migration.down(version: #{latest_version})", @colors[:highlight])}
         #{colorize("end", @colors[:highlight])}

      3. Run the migration:
         #{colorize("$ mix ecto.migrate", @colors[:brand])}

      📚 For more details, visit the ExLingo documentation.
      #{colorize("━━━━━━━━━━━━━━━━━━━━━━━━━━", @colors[:brand])}
      """

      IO.puts(warning_message)
    end
  end

  defp colorize(text, color) do
    IO.ANSI.format([color, text, @colors[:reset]])
    |> IO.chardata_to_string()
  end
end
