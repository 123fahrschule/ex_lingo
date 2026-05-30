defmodule ExLingo.AI.Providers.OpenAITest do
  # Not async: build_payload/1 now resolves the system prompt from the settings
  # row, which requires the database sandbox.
  use ExLingo.Test.DataCase, async: false

  alias ExLingo.AI.Providers.OpenAI
  alias ExLingo.AI.Translations.SuggestionRequest

  setup do
    ExLingo.Cache.delete_all()
    :ok
  end

  test "validates allowed and default models" do
    assert :ok =
             OpenAI.validate_config(
               allowed_models: ["gpt-5.4-nano"],
               default_model: "gpt-5.4-nano"
             )

    assert {:error, {:invalid_model, "gpt-5.5"}} =
             OpenAI.validate_config(
               allowed_models: ["gpt-5.4-nano"],
               default_model: "gpt-5.5"
             )
  end

  test "builds payload from the rendered prompt template" do
    payload =
      OpenAI.build_payload(%SuggestionRequest{
        source_locale: "en",
        target_locale: "de",
        target_locale_name: "German",
        source_text: "Download certificate",
        message_type: :singular,
        message_metadata: %{context: "button on the dashboard"},
        glossary_entries: [],
        current_translation: %{},
        model: "gpt-5.4-nano"
      })

    assert payload.model == "gpt-5.4-nano"
    assert [%{role: "user", content: prompt}] = payload.input

    assert prompt =~ "Return only the final translation text"
    assert prompt =~ "Download certificate"
    assert prompt =~ "button on the dashboard"
    refute prompt =~ "{{source_text}}"
    refute prompt =~ "{{context}}"
  end

  test "parses responses API output text" do
    assert {:ok, "Ausbildungsnachweis"} =
             OpenAI.parse_response(%{
               "output" => [
                 %{
                   "content" => [
                     %{"type" => "output_text", "text" => " Ausbildungsnachweis\n"}
                   ]
                 }
               ]
             })
  end

  test "rejects empty response text" do
    assert {:error, :empty_suggestion} = OpenAI.parse_response(%{"output_text" => "  "})
  end

  test "resolves API key from environment" do
    System.put_env("EX_LINGO_TEST_OPENAI_KEY", " test-key ")

    try do
      assert {:ok, "test-key"} = OpenAI.resolve_api_key({:system, "EX_LINGO_TEST_OPENAI_KEY"})
    after
      System.delete_env("EX_LINGO_TEST_OPENAI_KEY")
    end
  end
end
