defmodule ExLingo.Translations.ApplicationSource do
  @moduledoc """
  Application source DB model used when dealing with multiple apps, for example mobile app
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias ExLingo.Translations.Message

  @required_fields ~w(name)a
  @optional_fields ~w(description color)a

  @type t() :: ExLingo.Translations.ApplicationSourceSpec.t()

  @derive {Jason.Encoder, only: [:id] ++ @required_fields ++ @optional_fields}

  schema "ex_lingo_application_sources" do
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
    |> unique_constraint([:name])
  end
end
