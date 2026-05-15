defmodule ExLingo.Translations.Message do
  @moduledoc """
  Gettext message DB model
  """

  use ExLingo.Schema
  import Ecto.Changeset

  alias ExLingo.Translations.{
    ApplicationSource,
    Context,
    Domain,
    PluralTranslation,
    SingularTranslation
  }

  @required_fields ~w(msgid message_type)a
  @optional_fields ~w(domain_id context_id application_source_id source_references)a
  @relations ~w(domain context singular_translations plural_translations)a
  @max_msgid_length 10_000

  @type t() :: ExLingo.Translations.MessageSpec.t()

  @derive {Jason.Encoder, only: [:id] ++ @required_fields ++ @optional_fields ++ @relations}

  schema "ex_lingo_messages" do
    field :msgid, :string
    field :message_type, Ecto.Enum, values: [:singular, :plural]
    field :source_references, {:array, :map}, default: []

    belongs_to :domain, Domain
    belongs_to :context, Context
    belongs_to :application_source, ApplicationSource

    has_many :singular_translations, SingularTranslation
    has_many :plural_translations, PluralTranslation

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:msgid, max: @max_msgid_length)
  end
end
