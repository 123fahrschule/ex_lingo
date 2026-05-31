defmodule ExLingo.Translations.MessageSpec do
  @moduledoc """
  Includes type specs for message.
  """

  alias ExLingo.Translations.{
    Domain,
    Message,
    PluralTranslation,
    SingularTranslation
  }

  alias ExLingo.Types

  @type t() :: %Message{
          id: Types.field(Types.id()),
          msgid: Types.field(String.t()),
          context: Types.field(String.t()),
          message_type: :singular | :plural,
          source_references: [map()],
          context_review_requested_at: Types.field(DateTime.t()),
          context_review_context: Types.field(String.t()),
          domain: Types.field(Domain.t()),
          domain_id: Types.field(Types.id()),
          singular_translations: [SingularTranslation.t()],
          plural_translations: [PluralTranslation.t()],
          inserted_at: Types.field(NaiveDateTime.t()),
          updated_at: Types.field(NaiveDateTime.t())
        }
end
