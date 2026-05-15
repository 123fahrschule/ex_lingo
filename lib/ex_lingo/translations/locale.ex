defmodule ExLingo.Translations.Locale do
  @moduledoc """
  Locale DB model
  """

  use ExLingo.Schema
  import Ecto.Changeset
  alias ExLingo.Translations.SingularTranslation

  @required_fields ~w(iso639_code name native_name)a
  @optional_fields ~w(plurals_header family wiki_url colors)a
  @hex_color ~r/^#[0-9a-fA-F]{6}$/

  @type t() :: ExLingo.Translations.LocaleSpec.t()

  @derive {Jason.Encoder, only: [:id] ++ @required_fields ++ @optional_fields}

  schema "ex_lingo_locales" do
    field :iso639_code, :string
    field :name, :string
    field :native_name, :string
    field :family, :string
    field :wiki_url, :string
    field :plurals_header, :string

    field :colors, {:array, :string}

    has_many :singular_translations, SingularTranslation

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_change(:colors, &validate_colors/2)
    |> unique_constraint(:iso639_code)
  end

  defp validate_colors(:colors, colors) when is_list(colors) do
    if Enum.all?(colors, &(is_binary(&1) and Regex.match?(@hex_color, &1))) do
      []
    else
      [colors: "must contain only hex color values like #000000"]
    end
  end

  defp validate_colors(:colors, _colors), do: [colors: "must be a list of hex color values"]
end
