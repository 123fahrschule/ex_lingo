defmodule ExLingo.Translations.PluralTranslation do
  @moduledoc """
  Plural translation DB model
  """

  use ExLingo.Schema
  import Ecto.Changeset

  alias ExLingo.Translations.{Locale, Message}

  @required_fields ~w(nplural_index message_id locale_id)a
  @optional_fields ~w(original_text translated_text)a

  @type t() :: ExLingo.Translations.PluralTranslationSpec.t()

  @derive {Jason.Encoder, only: [:id] ++ @required_fields ++ @optional_fields}

  schema "ex_lingo_plural_translations" do
    field :nplural_index, :integer
    field :original_text, :string
    field :translated_text, :string

    belongs_to :locale, Locale
    belongs_to :message, Message

    timestamps()
  end

  def changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:locale_id)
    |> foreign_key_constraint(:message_id)
  end
end
