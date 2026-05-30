defmodule ExLingo.Storage.S3 do
  @moduledoc """
  Thin S3 helper for message-image storage.

  Credentials and bucket come from `ExLingo.Settings` (configured on the
  settings page), not from static config, so they can be changed at runtime.
  The actual HTTP work goes through a swappable client (`ExLingo.Storage.S3.Client`)
  so tests never hit the network.

  Object keys live under the configured folder prefix:
  `<prefix>/messages/<message_id>/<random>.<ext>`.
  """

  alias ExLingo.Settings

  @default_region "us-east-1"
  @default_expires_in 3600

  @doc "Whether enough S3 settings are present to talk to a bucket."
  @spec configured?() :: boolean()
  def configured? do
    setting = Settings.get()

    present?(setting.s3_access_key_id) and present?(setting.s3_secret_access_key) and
      present?(setting.s3_bucket)
  end

  @doc "ExAws-style config built from the current settings."
  @spec config() :: keyword()
  def config do
    setting = Settings.get()

    [
      access_key_id: setting.s3_access_key_id,
      secret_access_key: setting.s3_secret_access_key,
      region: presence(setting.s3_region) || @default_region
    ]
  end

  @doc "Configured bucket name."
  @spec bucket() :: String.t() | nil
  def bucket, do: Settings.get().s3_bucket

  @doc "Builds an object key for a message image under the configured prefix."
  @spec object_key(term(), String.t()) :: String.t()
  def object_key(message_id, filename) do
    ext = filename |> to_string() |> Path.extname() |> String.downcase()
    join_prefix("messages/#{message_id}/#{random_token()}#{ext}")
  end

  @doc "Uploads a binary to the bucket."
  @spec put(String.t(), binary(), String.t()) :: {:ok, term()} | {:error, term()}
  def put(key, binary, content_type) do
    bucket()
    |> ExAws.S3.put_object(key, binary, content_type: content_type)
    |> request()
  end

  @doc "Deletes an object from the bucket."
  @spec delete(String.t()) :: {:ok, term()} | {:error, term()}
  def delete(key) do
    bucket()
    |> ExAws.S3.delete_object(key)
    |> request()
  end

  @doc """
  Returns a presigned URL for `key`. Defaults to a short-lived GET URL for
  displaying private images; pass `method: :put` for a direct browser upload.
  """
  @spec presigned_url(String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def presigned_url(key, opts \\ []) do
    method = Keyword.get(opts, :method, :get)
    expires_in = Keyword.get(opts, :expires_in, @default_expires_in)

    ExAws.S3.presigned_url(
      ExAws.Config.new(:s3, config()),
      method,
      bucket(),
      key,
      expires_in: expires_in
    )
  end

  @doc """
  Checks bucket connectivity for the settings page. Returns `:ok`,
  `{:error, :not_configured}`, or `{:error, reason}`.
  """
  @spec test_connection() :: :ok | {:error, term()}
  def test_connection do
    if configured?() do
      bucket()
      |> ExAws.S3.head_bucket()
      |> request()
      |> case do
        {:ok, _result} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :not_configured}
    end
  end

  defp request(operation), do: client().request(operation, config())

  defp client do
    Application.get_env(:ex_lingo, :s3_client, ExLingo.Storage.S3.ExAwsClient)
  end

  defp join_prefix(path) do
    case normalize_prefix(Settings.get().s3_prefix) do
      "" -> path
      prefix -> prefix <> "/" <> path
    end
  end

  defp normalize_prefix(nil), do: ""
  defp normalize_prefix(prefix), do: prefix |> String.trim() |> String.trim("/")

  defp random_token, do: 16 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

  defp present?(value), do: is_binary(value) and String.trim(value) != ""

  defp presence(value), do: if(present?(value), do: value, else: nil)
end
