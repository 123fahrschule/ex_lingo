defmodule ExLingo.Encrypted.Cipher do
  @moduledoc false

  # AES-256-GCM over OTP's `:crypto`. The wire format is the one historically
  # produced by Cloak's `Cloak.Ciphers.AES.GCM` (tag "AES.GCM.V1"), so values
  # stored by earlier releases stay readable without a data migration:
  #
  #     <<1, 10, "AES.GCM.V1">> <> iv(12) <> tag(16) <> ciphertext
  #
  # The key is the SHA-256 of the configured secret and the AAD is
  # "AES256GCM". A fresh random IV is used for every encryption.

  @cipher :aes_256_gcm
  @aad "AES256GCM"
  @key_tag "AES.GCM.V1"
  @header <<1, byte_size(@key_tag), @key_tag::binary>>
  @iv_length 12
  @tag_length 16

  @spec encrypt(binary(), term()) :: binary()
  def encrypt(plaintext, secret) when is_binary(plaintext) do
    iv = :crypto.strong_rand_bytes(@iv_length)

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(
        @cipher,
        derive_key(secret),
        iv,
        plaintext,
        @aad,
        @tag_length,
        true
      )

    @header <> iv <> tag <> ciphertext
  end

  @spec decrypt(term(), term()) :: {:ok, binary()} | :error
  def decrypt(
        <<@header, iv::binary-size(@iv_length), tag::binary-size(@tag_length),
          ciphertext::binary>>,
        secret
      ) do
    case :crypto.crypto_one_time_aead(
           @cipher,
           derive_key(secret),
           iv,
           ciphertext,
           @aad,
           tag,
           false
         ) do
      plaintext when is_binary(plaintext) -> {:ok, plaintext}
      _ -> :error
    end
  end

  def decrypt(_value, _secret), do: :error

  defp derive_key(secret), do: :crypto.hash(:sha256, to_string(secret))
end
