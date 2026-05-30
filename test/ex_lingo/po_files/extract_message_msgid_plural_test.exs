defmodule ExLingo.PoFiles.ExtractMessageMsgidPluralTest do
  use ExLingo.Test.DataCase, async: false

  alias ExLingo.PoFiles.Services.ExtractMessage

  setup do
    ExLingo.Cache.delete_all()
    :ok
  end

  test "captures msgid_plural when importing a plural message" do
    assert {:ok, message} =
             ExtractMessage.call(%{
               msgid: "apple",
               msgid_plural: "apples",
               message_type: :plural,
               context_name: "default",
               domain_name: nil
             })

    assert message.msgid_plural == "apples"
  end

  test "updates msgid_plural when the source plural form changes on re-import" do
    {:ok, _} =
      ExtractMessage.call(%{
        msgid: "apple",
        msgid_plural: "apples",
        message_type: :plural,
        context_name: "default",
        domain_name: nil
      })

    assert {:ok, message} =
             ExtractMessage.call(%{
               msgid: "apple",
               msgid_plural: "%{count} apples",
               message_type: :plural,
               context_name: "default",
               domain_name: nil
             })

    assert message.msgid_plural == "%{count} apples"
  end
end
