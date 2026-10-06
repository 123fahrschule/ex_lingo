defmodule ExLingo.Encrypted.Binary do
  @moduledoc """
  Ecto type for binary fields encrypted at rest with AES-256-GCM.

  Values are transparently encrypted on write and decrypted on read. The key is
  derived (SHA-256) from `config :ex_lingo, :settings_encryption_key`, which is
  read from the application environment on every call. Host applications should
  set it to a strong, stable secret — changing it makes previously encrypted
  values unreadable. A fixed fallback is used only when nothing is configured so
  that development and tests work out of the box.

  A stored value that cannot be decrypted (wrong key, damaged or foreign data)
  loads as `nil` (a warning is logged) instead of failing the whole row read, so
  one unreadable secret cannot take down the dashboard. The stored bytes are not
  touched: restoring the original key makes the value readable again, and
  entering a new value overwrites it. Neither the key nor any plaintext (or
  ciphertext) is ever included in a log message or error.
  """

  use Ecto.Type

  require Logger

  alias ExLingo.Encrypted.Cipher

  @fallback_secret "ex_lingo_default_settings_encryption_key"

  @impl Ecto.Type
  def type, do: :binary

  @impl Ecto.Type
  def cast(nil), do: {:ok, nil}
  def cast(value) when is_binary(value), do: {:ok, value}
  def cast(_value), do: :error

  @impl Ecto.Type
  def dump(nil), do: {:ok, nil}
  def dump(value) when is_binary(value), do: {:ok, Cipher.encrypt(value, secret())}
  def dump(_value), do: :error

  @impl Ecto.Type
  def load(nil), do: {:ok, nil}

  def load(value) do
    case Cipher.decrypt(value, secret()) do
      {:ok, plaintext} ->
        {:ok, plaintext}

      :error ->
        Logger.warning(
          "[ExLingo] An encrypted setting could not be decrypted (wrong :settings_encryption_key " <>
            "or damaged data); treating it as unset. The stored value was left untouched."
        )

        {:ok, nil}
    end
  end

  @impl Ecto.Type
  def embed_as(_format), do: :self

  @impl Ecto.Type
  def equal?(term1, term2), do: term1 == term2

  defp secret, do: Application.get_env(:ex_lingo, :settings_encryption_key) || @fallback_secret
end
