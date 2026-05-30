defmodule ExLingo.Encrypted.Binary do
  @moduledoc """
  Ecto type for binary fields encrypted at rest via `ExLingo.Vault`.
  Values are transparently encrypted on write and decrypted on read.
  """

  use Cloak.Ecto.Binary, vault: ExLingo.Vault
end
