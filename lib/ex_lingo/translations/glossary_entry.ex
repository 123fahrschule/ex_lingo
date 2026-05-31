defmodule ExLingo.Translations.GlossaryEntry do
  @moduledoc """
  Glossary entry DB model for approved translation terminology.
  """

  use ExLingo.Schema
  import Ecto.Changeset

  alias ExLingo.Translations.Domain

  @required_fields ~w(source_locale target_locale source_term target_term)a
  @optional_fields ~w(usage_guidance domain_id)a
  @relations ~w(domain)a
  @locale_format ~r/^[a-z]{2}(?:[_-][a-z]+)?$/

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder, only: [:id] ++ @required_fields ++ @optional_fields ++ @relations}

  schema "ex_lingo_glossary_entries" do
    field :source_locale, :string
    field :target_locale, :string
    field :source_term, :string
    field :target_term, :string
    field :usage_guidance, :string

    belongs_to :domain, Domain

    timestamps()
  end

  def changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> normalize_locale(:source_locale)
    |> normalize_locale(:target_locale)
    |> validate_required(@required_fields)
    |> validate_length(:source_locale, min: 2, max: 16)
    |> validate_length(:target_locale, min: 2, max: 16)
    |> validate_format(:source_locale, @locale_format,
      message: "must be a locale code like en or en-us"
    )
    |> validate_format(:target_locale, @locale_format,
      message: "must be a locale code like en or en-us"
    )
    |> validate_length(:source_term, min: 1, max: 255)
    |> validate_length(:target_term, min: 1, max: 255)
    |> foreign_key_constraint(:domain_id)
  end

  defp normalize_locale(changeset, field) do
    update_change(changeset, field, fn
      nil -> nil
      locale -> locale |> String.trim() |> String.downcase()
    end)
  end
end
