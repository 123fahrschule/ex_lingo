defmodule ExLingo.Migrations.Postgresql.V08 do
  @moduledoc """
  ExLingo PostgreSQL V8 Migrations

  Introduces the single-row `ex_lingo_settings` table that backs the settings
  dashboard (configurable AI system prompts, S3 storage credentials).
  """

  use Ecto.Migration

  @default_prefix "public"
  @ex_lingo_settings "ex_lingo_settings"

  def up(opts) do
    prefix = prefix(opts)

    create_if_not_exists table(@ex_lingo_settings, prefix: prefix, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:ai_prompt_template, :text)
      add(:ai_prompt_template_per_locale, :map, null: false, default: %{})
      add(:s3_access_key_id, :text)
      add(:s3_secret_access_key, :binary)
      add(:s3_bucket, :text)
      add(:s3_region, :text)
      add(:s3_prefix, :text, null: false, default: "/")
      timestamps()
    end
  end

  def down(opts) do
    drop_if_exists table(@ex_lingo_settings, prefix: prefix(opts))
  end

  defp prefix(opts), do: Map.get(opts, :prefix, @default_prefix)
end
