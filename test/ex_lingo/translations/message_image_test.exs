defmodule ExLingo.Translations.MessageImageTest do
  use ExLingo.Test.DataCase, async: false

  alias ExLingo.Translations

  setup do
    ExLingo.Cache.delete_all()

    {:ok, message} =
      Translations.create_message(%{msgid: "Book now", message_type: :singular})

    %{message: message}
  end

  describe "create_image/3 and list_images/1" do
    test "stores image metadata and lists oldest first", %{message: message} do
      {:ok, first} =
        Translations.create_message_image(message.id, %{
          s3_key: "messages/#{message.id}/a.png",
          content_type: "image/png",
          byte_size: 1234
        })

      {:ok, second} =
        Translations.create_message_image(message.id, %{
          s3_key: "messages/#{message.id}/b.png",
          content_type: "image/png",
          byte_size: 5678
        })

      ids = message.id |> Translations.list_message_images() |> Enum.map(& &1.id)
      assert ids == [first.id, second.id]
    end

    test "requires an s3 key", %{message: message} do
      assert {:error, changeset} = Translations.create_message_image(message.id, %{})
      assert %{s3_key: [_]} = errors_on(changeset)
    end

    test "rejects a duplicate s3 key", %{message: message} do
      attrs = %{s3_key: "messages/#{message.id}/dup.png"}
      {:ok, _} = Translations.create_message_image(message.id, attrs)

      assert {:error, changeset} = Translations.create_message_image(message.id, attrs)
      assert %{s3_key: [_]} = errors_on(changeset)
    end
  end

  describe "delete_image/2" do
    test "removes the row", %{message: message} do
      {:ok, image} =
        Translations.create_message_image(message.id, %{s3_key: "messages/#{message.id}/x.png"})

      assert {:ok, _} = Translations.delete_message_image(image.id)
      assert Translations.list_message_images(message.id) == []
    end

    test "returns not_found for an unknown id" do
      assert {:error, :not_found} = Translations.delete_message_image(-1)
    end
  end

  describe "image_counts/1" do
    test "counts images per message", %{message: message} do
      {:ok, other} = Translations.create_message(%{msgid: "Cancel", message_type: :singular})

      Translations.create_message_image(message.id, %{s3_key: "a"})
      Translations.create_message_image(message.id, %{s3_key: "b"})
      Translations.create_message_image(other.id, %{s3_key: "c"})

      counts = Translations.message_image_counts([message.id, other.id])
      assert counts[message.id] == 2
      assert counts[other.id] == 1
    end

    test "returns an empty map for no ids" do
      assert Translations.message_image_counts([]) == %{}
    end
  end

  describe "move_images/3" do
    test "reassigns images to another message", %{message: message} do
      {:ok, target} = Translations.create_message(%{msgid: "Save", message_type: :singular})
      Translations.create_message_image(message.id, %{s3_key: "m1"})
      Translations.create_message_image(message.id, %{s3_key: "m2"})

      Translations.move_message_images(message.id, target.id)

      assert Translations.list_message_images(message.id) == []
      assert length(Translations.list_message_images(target.id)) == 2
    end
  end

  test "deleting a message cascades to its images", %{message: message} do
    Translations.create_message_image(message.id, %{s3_key: "cascade"})
    {:ok, _stats} = Translations.delete_message(message.id)

    assert Translations.list_message_images(message.id) == []
  end

  test "merging messages transfers images to the target", %{message: message} do
    {:ok, target} = Translations.create_message(%{msgid: "Reserve", message_type: :singular})
    Translations.create_message_image(message.id, %{s3_key: "merge-1"})
    Translations.create_message_image(message.id, %{s3_key: "merge-2"})

    {:ok, _} = Translations.merge_messages(message.id, target.id)

    # Source is gone, its images now belong to the target rather than being lost.
    assert length(Translations.list_message_images(target.id)) == 2
  end
end
