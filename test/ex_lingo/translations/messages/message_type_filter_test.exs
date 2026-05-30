defmodule ExLingo.Translations.Messages.MessageTypeFilterTest do
  use ExLingo.Test.DataCase, async: false

  alias ExLingo.Translations

  setup do
    ExLingo.Cache.delete_all()

    {:ok, _} = Translations.create_message(%{msgid: "Save", message_type: :singular})
    {:ok, _} = Translations.create_message(%{msgid: "apple", message_type: :plural})

    :ok
  end

  defp list(filter) do
    %{entries: entries} = Translations.list_messages(filter: filter)
    Enum.map(entries, & &1.message_type)
  end

  test "filters by singular" do
    assert list(%{"message_type" => "singular"}) == [:singular]
  end

  test "filters by plural" do
    assert list(%{"message_type" => "plural"}) == [:plural]
  end

  test "returns both types without a type filter" do
    assert list(%{}) |> Enum.sort() == [:plural, :singular]
  end

  test "ignores an invalid type value" do
    assert list(%{"message_type" => "bogus"}) |> Enum.sort() == [:plural, :singular]
  end
end
