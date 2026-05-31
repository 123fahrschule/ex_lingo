defmodule ExLingoWeb.I18nTest do
  use ExUnit.Case, async: true

  alias ExLingoWeb.I18n

  defp conn(fields) do
    struct(Plug.Conn, Map.merge(%{params: %{}, assigns: %{}, cookies: %{}}, fields))
  end

  describe "locale_from_conn/1" do
    test "the shared Cognit app_locale cookie wins over a stale ?locale param" do
      conn = conn(%{params: %{"locale" => "en"}, cookies: %{"app_locale" => "de"}})

      assert I18n.locale_from_conn(conn) == "de"
    end

    test "conn assigns locale (Cognit.LocalePlug) wins over a stale ?locale param" do
      conn = conn(%{params: %{"locale" => "en"}, assigns: %{locale: "de"}})

      assert I18n.locale_from_conn(conn) == "de"
    end

    test "conn assigns locale wins over the app_locale cookie" do
      conn = conn(%{assigns: %{locale: "de"}, cookies: %{"app_locale" => "en"}})

      assert I18n.locale_from_conn(conn) == "de"
    end

    test "falls back to the legacy ?locale handoff param when no cognit source is present" do
      conn = conn(%{params: %{"locale" => "de"}})

      assert I18n.locale_from_conn(conn) == "de"
    end

    test "defaults to en when nothing is set" do
      assert I18n.locale_from_conn(conn(%{})) == "en"
    end
  end
end
