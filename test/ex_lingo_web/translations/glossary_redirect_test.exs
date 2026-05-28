defmodule ExLingoWeb.Translations.GlossaryRedirectTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExLingoWeb.Translations.GlossaryRedirect

  defp build_message(opts \\ []) do
    %{
      msgid: Keyword.get(opts, :msgid, "Welcome"),
      domain_id: Keyword.get(opts, :domain_id),
      application_source_id: Keyword.get(opts, :application_source_id)
    }
  end

  defp locale, do: %{iso639_code: "de"}

  test "builds query with explicit terms" do
    query =
      GlossaryRedirect.query_params(
        build_message(),
        locale(),
        %{"source_term" => "welcome", "target_term" => "willkommen"},
        "/locales/1/translations"
      )

    params = URI.decode_query(query)

    assert params["source_locale"] == "en"
    assert params["target_locale"] == "de"
    assert params["source_term"] == "welcome"
    assert params["target_term"] == "willkommen"
    assert params["return_to"] == "/locales/1/translations"
    refute Map.has_key?(params, "domain_id")
  end

  test "falls back to msgid when source_term is blank" do
    query =
      GlossaryRedirect.query_params(
        build_message(msgid: "Welcome"),
        locale(),
        %{"source_term" => "   ", "target_term" => ""},
        "/back"
      )

    params = URI.decode_query(query)

    assert params["source_term"] == "Welcome"
    assert params["target_term"] == ""
  end

  test "includes scope ids when present" do
    query =
      GlossaryRedirect.query_params(
        build_message(domain_id: 5, application_source_id: 9),
        locale(),
        %{"source_term" => "x", "target_term" => "y"},
        "/back"
      )

    params = URI.decode_query(query)

    assert params["domain_id"] == "5"
    assert params["application_source_id"] == "9"
  end

  test "trims whitespace around supplied terms" do
    query =
      GlossaryRedirect.query_params(
        build_message(),
        locale(),
        %{"source_term" => "  hi  ", "target_term" => "  hallo  "},
        "/back"
      )

    params = URI.decode_query(query)

    assert params["source_term"] == "hi"
    assert params["target_term"] == "hallo"
  end
end
