defmodule ExLingo.Translations.DomainSpec do
  @moduledoc """
  Includes type specs for domain.
  """

  alias ExLingo.Translations.{Domain, Message}
  alias ExLingo.Types

  @type t() :: %Domain{
          id: Types.field(Types.id()),
          name: Types.field(String.t()),
          description: Types.field(String.t()),
          color: Types.field(String.t()),
          messages: [Message.t()],
          inserted_at: Types.field(NaiveDateTime.t()),
          updated_at: Types.field(NaiveDateTime.t())
        }
end
