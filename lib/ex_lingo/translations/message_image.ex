defmodule ExLingo.Translations.MessageImage do
  @moduledoc """
  An image (screenshot/mockup) attached to a message for visual translation
  context. The binary lives in S3; this row only stores the object key and
  metadata.
  """

  use ExLingo.Schema
  import Ecto.Changeset

  alias ExLingo.Translations.Message

  @required_fields ~w(message_id s3_key)a
  @optional_fields ~w(content_type byte_size uploaded_by)a

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
           only: [:id, :message_id, :s3_key, :content_type, :byte_size, :uploaded_by]}

  schema "ex_lingo_message_images" do
    field :s3_key, :string
    field :content_type, :string
    field :byte_size, :integer
    field :uploaded_by, :string

    belongs_to :message, Message

    timestamps()
  end

  def changeset(struct, attrs \\ %{}) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:byte_size, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:message_id)
    |> unique_constraint(:s3_key)
  end
end
