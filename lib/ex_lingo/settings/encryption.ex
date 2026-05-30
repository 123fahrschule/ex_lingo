defmodule ExLingo.Settings.Encryption do
  @moduledoc """
  AES-256-GCM encryption for sensitive settings values (e.g. the S3 secret
  access key).

  The encryption key is derived (SHA-256) from either an explicitly configured
  `config :ex_lingo, :settings_encryption_key` or, as a fallback, the host
  application endpoint's `:secret_key_base`. Secrets are never stored in
  plaintext.

  The stored blob layout is `iv (12 bytes) <> tag (16 bytes) <> ciphertext`.
  """

  @aad "ex_lingo_settings"
  @iv_size 12
  @tag_size 16

  @spec encrypt(binary() | nil) :: binary() | nil
  def encrypt(nil), do: nil
  def encrypt(""), do: nil

  def encrypt(plaintext) when is_binary(plaintext) do
    iv = :crypto.strong_rand_bytes(@iv_size)

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key(), iv, plaintext, @aad, true)

    iv <> tag <> ciphertext
  end

  @spec decrypt(binary() | nil) :: binary() | nil
  def decrypt(nil), do: nil

  def decrypt(<<iv::binary-size(@iv_size), tag::binary-size(@tag_size), ciphertext::binary>>) do
    case :crypto.crypto_one_time_aead(:aes_256_gcm, key(), iv, ciphertext, @aad, tag, false) do
      plaintext when is_binary(plaintext) -> plaintext
      _error -> nil
    end
  end

  def decrypt(_blob), do: nil

  defp key do
    secret = Application.get_env(:ex_lingo, :settings_encryption_key) || endpoint_secret()
    :crypto.hash(:sha256, to_string(secret))
  end

  defp endpoint_secret do
    ExLingo.config().endpoint.config(:secret_key_base)
  rescue
    _error -> "ex_lingo_default_settings_encryption_key"
  end
end
