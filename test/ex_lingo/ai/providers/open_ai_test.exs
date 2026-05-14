defmodule ExLingo.AI.Providers.OpenAITest do
  use ExUnit.Case, async: true

  alias ExLingo.AI.Providers.OpenAI
  alias ExLingo.AI.Translations.SuggestionRequest

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

  test "builds payload that requests translation text only" do
    payload =
      OpenAI.build_payload(%SuggestionRequest{
        source_locale: "en",
        target_locale: "de",
        target_locale_name: "German",
        source_text: "Download certificate",
        message_type: :singular,
        glossary_entries: [],
        current_translation: %{},
        model: "gpt-5.4-nano"
      })

    assert payload.model == "gpt-5.4-nano"
    system_prompt = payload.input |> List.first() |> Map.fetch!(:content)
    user_prompt = payload.input |> List.last() |> Map.fetch!(:content)

    assert system_prompt =~ "Return only the final translation text"
    assert user_prompt =~ "Download certificate"
    assert user_prompt =~ "Glossary"
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
