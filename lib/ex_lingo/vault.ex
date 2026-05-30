defmodule ExLingo.Vault do
  @moduledoc """
  Cloak vault used to encrypt sensitive settings at rest (e.g. the S3 secret
  access key).

  The AES-256-GCM key is derived (SHA-256) from
  `config :ex_lingo, :settings_encryption_key`. Host applications should set
  this to a strong, stable secret — rotating it makes previously encrypted
  values unreadable. A fixed fallback is used only when nothing is configured
  so that development and tests work out of the box.
  """

  use Cloak.Vault, otp_app: :ex_lingo

  @fallback_secret "ex_lingo_default_settings_encryption_key"

  @impl GenServer
  def init(config) do
    ciphers = [
      default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: key(), iv_length: 12}
    ]

    {:ok, Keyword.put(config, :ciphers, ciphers)}
  end

  defp key do
    secret = Application.get_env(:ex_lingo, :settings_encryption_key) || @fallback_secret
    :crypto.hash(:sha256, to_string(secret))
  end
end
