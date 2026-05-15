defmodule ExLingo.AI.Translations.Plugin.FormComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias ExLingo.AI.Translations.Plugin.FormComponent

  test "renders missing provider state" do
    html =
      render_component(&FormComponent.render/1,
        id: "ai-suggestion",
        myself: nil,
        provider_options: [],
        selected_provider_id: nil,
        selected_model: nil,
        suggestion: nil,
        adapted_text: nil,
        adapting?: false,
        error: nil
      )

    assert html =~ "No AI translation provider is configured"
  end

  test "renders provider and model selectors" do
    html =
      render_component(&FormComponent.render/1,
        id: "ai-suggestion",
        myself: nil,
        provider_options: [
          %{
            id: "Elixir.ExLingo.AI.Providers.OpenAI",
            name: "OpenAI",
            models: ["gpt-5.4-nano", "gpt-5.4-mini"],
            default_model: "gpt-5.4-nano"
          }
        ],
        selected_provider_id: "Elixir.ExLingo.AI.Providers.OpenAI",
        selected_model: "gpt-5.4-nano",
        suggestion: nil,
        adapted_text: nil,
        adapting?: false,
        error: nil
      )

    assert html =~ "OpenAI"
    assert html =~ "gpt-5.4-nano"
    assert html =~ "gpt-5.4-mini"
    assert html =~ "Suggest"
  end

  test "renders suggestion text without provider metadata fields" do
    html =
      render_component(&FormComponent.render/1,
        id: "ai-suggestion",
        myself: nil,
        provider_options: [provider_option()],
        selected_provider_id: provider_option().id,
        selected_model: "gpt-5.4-nano",
        suggestion: "Ausbildungsnachweis herunterladen",
        adapted_text: "Ausbildungsnachweis herunterladen",
        adapting?: false,
        error: nil
      )

    assert html =~ "Ausbildungsnachweis herunterladen"
    assert html =~ "Accept"
    assert html =~ "Adapt"
    refute html =~ "Confidence"
    refute html =~ "Notes"
  end

  test "renders adapted suggestion form" do
    html =
      render_component(&FormComponent.render/1,
        id: "ai-suggestion",
        myself: nil,
        provider_options: [provider_option()],
        selected_provider_id: provider_option().id,
        selected_model: "gpt-5.4-nano",
        suggestion: "Ausbildungsnachweis herunterladen",
        adapted_text: "Ausbildungsbescheinigung herunterladen",
        adapting?: true,
        error: nil
      )

    assert html =~ "Adapted suggestion"
    assert html =~ "Ausbildungsbescheinigung herunterladen"
    assert html =~ "Save"
  end

  test "renders provider errors" do
    html =
      render_component(&FormComponent.render/1,
        id: "ai-suggestion",
        myself: nil,
        provider_options: [provider_option()],
        selected_provider_id: provider_option().id,
        selected_model: "gpt-5.4-nano",
        suggestion: nil,
        adapted_text: nil,
        adapting?: false,
        error: "The AI provider API key is missing."
      )

    assert html =~ "The AI provider API key is missing."
  end

  test "renders loading state while suggestion is generating" do
    html =
      render_component(&FormComponent.render/1,
        id: "ai-suggestion",
        myself: nil,
        provider_options: [provider_option()],
        selected_provider_id: provider_option().id,
        selected_model: "gpt-5.4-nano",
        suggestion: nil,
        adapted_text: nil,
        adapting?: false,
        loading?: true,
        error: nil
      )

    assert html =~ "Generating suggestion"
    assert html =~ "Generating..."
  end

  defp provider_option do
    %{
      id: "Elixir.ExLingo.AI.Providers.OpenAI",
      name: "OpenAI",
      models: ["gpt-5.4-nano"],
      default_model: "gpt-5.4-nano"
    }
  end
end
