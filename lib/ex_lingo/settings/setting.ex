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
    validation_length_warning_ratio
    validation_length_error_ratio
    validation_short_string_threshold
    validation_short_abs_warning
    validation_short_abs_error
  )a

  @validation_ratio_fields ~w(validation_length_warning_ratio validation_length_error_ratio)a
  @validation_integer_fields ~w(
    validation_short_string_threshold
    validation_short_abs_warning
    validation_short_abs_error
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

    # Translator quality-warning thresholds. nil = fall back to app config /
    # built-in defaults (see ExLingo.Settings.validations/0). Mobile UIs are
    # typically configured stricter than web UIs.
    field :validation_length_warning_ratio, :float
    field :validation_length_error_ratio, :float
    field :validation_short_string_threshold, :integer
    field :validation_short_abs_warning, :integer
    field :validation_short_abs_error, :integer

    timestamps()
  end

  def changeset(struct, attrs \\ %{}) do
    struct
    |> cast(normalize_decimal_separators(attrs), @castable_fields)
    |> normalize_per_locale()
    |> normalize_s3_prefix()
    |> drop_blank_secret()
    |> validate_thresholds()
  end

  # Accept a comma as the decimal separator for the ratio fields (e.g. German
  # users typing "1,3"), since Ecto's :float cast only understands ".".
  defp normalize_decimal_separators(attrs) when is_map(attrs) do
    Enum.reduce(@validation_ratio_fields, attrs, fn field, acc ->
      acc
      |> swap_comma_at(Atom.to_string(field))
      |> swap_comma_at(field)
    end)
  end

  defp normalize_decimal_separators(attrs), do: attrs

  defp swap_comma_at(attrs, key) do
    case attrs do
      %{^key => value} when is_binary(value) ->
        Map.put(attrs, key, String.replace(value, ",", "."))

      _other ->
        attrs
    end
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

  defp validate_thresholds(changeset) do
    changeset =
      Enum.reduce(@validation_ratio_fields, changeset, fn field, acc ->
        validate_number(acc, field, greater_than: 0)
      end)

    changeset =
      Enum.reduce(@validation_integer_fields, changeset, fn field, acc ->
        validate_number(acc, field, greater_than_or_equal_to: 0)
      end)

    changeset
    |> validate_order(:validation_length_warning_ratio, :validation_length_error_ratio)
    |> validate_order(:validation_short_abs_warning, :validation_short_abs_error)
  end

  # The error threshold must not be below the warning threshold.
  defp validate_order(changeset, warning_field, error_field) do
    warning = get_field(changeset, warning_field)
    error = get_field(changeset, error_field)

    if is_number(warning) and is_number(error) and error < warning do
      add_error(changeset, error_field, "must be greater than or equal to the warning threshold")
    else
      changeset
    end
  end
end
