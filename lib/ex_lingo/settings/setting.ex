defmodule ExLingo.Settings.Setting do
  @moduledoc """
  Single-row settings model for ExLingo.

  Holds the configurable AI translation system prompts (a global default plus
  optional per-locale overrides) and the S3 storage credentials. The S3 secret
  access key is encrypted at rest via `ExLingo.Vault` (Cloak); it is decrypted
  transparently on load and is never rendered back into forms.
  """

  use ExLingo.Schema
  import Ecto.Changeset

  @castable_fields ~w(
    ai_prompt_template
    ai_prompt_template_per_locale
    s3_access_key_id
    s3_bucket
    s3_region
    s3_prefix
    s3_secret_access_key
  )a

  @default_s3_prefix "/"

  @type t :: %__MODULE__{}

  schema "ex_lingo_settings" do
    field :ai_prompt_template, :string
    field :ai_prompt_template_per_locale, :map, default: %{}
    field :s3_access_key_id, :string
    field :s3_secret_access_key, ExLingo.Encrypted.Binary, redact: true
    field :s3_bucket, :string
    field :s3_region, :string
    field :s3_prefix, :string, default: @default_s3_prefix

    timestamps()
  end

  def changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, @castable_fields)
    |> normalize_per_locale()
    |> normalize_s3_prefix()
    |> drop_blank_secret()
  end

  @doc "Whether an S3 secret access key has been stored."
  def s3_secret_present?(%__MODULE__{s3_secret_access_key: secret}) do
    is_binary(secret) and secret != ""
  end

  defp normalize_per_locale(changeset) do
    case fetch_change(changeset, :ai_prompt_template_per_locale) do
      {:ok, map} when is_map(map) ->
        cleaned =
          map
          |> Enum.filter(fn {_code, prompt} ->
            is_binary(prompt) and String.trim(prompt) != ""
          end)
          |> Map.new(fn {code, prompt} -> {to_string(code), prompt} end)

        put_change(changeset, :ai_prompt_template_per_locale, cleaned)

      _other ->
        changeset
    end
  end

  # A blank or missing prefix falls back to the bucket root, so a shared bucket
  # can still be used without configuring a per-service subfolder.
  defp normalize_s3_prefix(changeset) do
    case fetch_change(changeset, :s3_prefix) do
      {:ok, value} ->
        prefix = if is_binary(value), do: String.trim(value), else: ""
        put_change(changeset, :s3_prefix, if(prefix == "", do: @default_s3_prefix, else: prefix))

      :error ->
        changeset
    end
  end

  # A blank secret leaves the stored value untouched, so users can edit other
  # S3 fields without re-entering the secret.
  defp drop_blank_secret(changeset) do
    case fetch_change(changeset, :s3_secret_access_key) do
      {:ok, value} when not is_binary(value) or value == "" ->
        delete_change(changeset, :s3_secret_access_key)

      _other ->
        changeset
    end
  end
end
