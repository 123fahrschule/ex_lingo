defmodule ExLingo.Migrations.Postgresql.V09 do
  @moduledoc """
  ExLingo PostgreSQL V9 Migrations

  Adds `ex_lingo_message_images`, which links uploaded screenshots/mockups
  (stored in S3) to a message for visual translation context.
  """

  use Ecto.Migration

  @default_prefix "public"
  @ex_lingo_messages "ex_lingo_messages"
  @ex_lingo_message_images "ex_lingo_message_images"

  def up(opts) do
    prefix = prefix(opts)

    create_if_not_exists table(@ex_lingo_message_images, prefix: prefix, primary_key: false) do
      add(:id, :bigserial, primary_key: true)

      add(
        :message_id,
        references(@ex_lingo_messages, prefix: prefix, type: :bigint, on_delete: :delete_all),
        null: false
      )

      add(:s3_key, :text, null: false)
      add(:content_type, :text)
      add(:byte_size, :bigint)
      add(:uploaded_by, :text)
      timestamps()
    end

    create_if_not_exists index(@ex_lingo_message_images, [:message_id], prefix: prefix)
    create_if_not_exists unique_index(@ex_lingo_message_images, [:s3_key], prefix: prefix)
  end

  def down(opts) do
    drop_if_exists table(@ex_lingo_message_images, prefix: prefix(opts))
  end

  defp prefix(opts), do: Map.get(opts, :prefix, @default_prefix)
end
