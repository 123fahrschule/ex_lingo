defmodule ExLingo.Translations.ApplicationSourceSpec do
  @moduledoc """
  Includes type specs for application source.
  """

  alias ExLingo.Translations.{ApplicationSource, Message}
  alias ExLingo.Types

  @type t() :: %ApplicationSource{
          id: Types.field(Types.id()),
          name: Types.field(String.t()),
          description: Types.field(String.t()),
          color: Types.field(String.t()),
          messages: [Message.t()],
          inserted_at: Types.field(NaiveDateTime.t()),
          updated_at: Types.field(NaiveDateTime.t())
        }
end
