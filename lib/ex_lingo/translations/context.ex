defmodule ExLingo.Translations.Context do
  @moduledoc """
  Gettext Context DB model
  """

  use ExLingo.Schema
  import Ecto.Changeset

  alias ExLingo.Translations.Message

  @required_fields ~w(name)a
  @optional_fields ~w(description color)a

  @type t() :: ExLingo.Translations.ContextSpec.t()

  @derive {Jason.Encoder, only: [:id] ++ @required_fields ++ @optional_fields}

  schema "ex_lingo_contexts" do
    field :name, :string
    field :description, :string
    field :color, :string

    has_many :messages, Message

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
