defmodule ExLingo.Translations.Context do
  @moduledoc """
  Gettext Context DB model
  """

  use ExLingo.Schema
  import Ecto.Changeset

  alias ExLingo.Translations.Message

  @required_fields ~w(name)a
  @optional_fields ~w(description color)a
  @hex_color ~r/^#[0-9a-fA-F]{6}$/

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
    |> update_change(:color, &normalize_color/1)
    |> validate_change(:color, &validate_color/2)
    |> unique_constraint(:name)
  end

  defp normalize_color(color) when is_binary(color) do
    color
    |> String.trim()
    |> String.upcase()
  end

  defp normalize_color(color), do: color

  defp validate_color(:color, nil), do: [color: "can't be blank"]

  defp validate_color(:color, color) when is_binary(color) do
    if Regex.match?(@hex_color, color) do
      []
    else
      [color: "must be a hex color like #7E37D8"]
    end
  end

  defp validate_color(:color, _color), do: [color: "must be a hex color like #7E37D8"]
end
