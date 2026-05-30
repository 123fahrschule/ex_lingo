defmodule ExLingoWeb.Settings.SettingsLiveTest do
  use ExLingo.Test.DataCase, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias ExLingo.Settings
  alias ExLingo.Translations
  alias ExLingoWeb.Settings.SettingsLive

  @endpoint ExLingo.Test.Endpoint

  setup do
    ExLingo.Cache.delete_all()

    {:ok, locale} =
      Translations.create_locale(%{
        iso639_code: "de",
        name: "German",
        native_name: "Deutsch"
      })

    %{locale: locale}
  end

  test "renders the AI prompt and S3 storage sections", %{locale: locale} do
    {:ok, _view, html} = build_conn() |> live_isolated(SettingsLive, session: %{})

    assert html =~ "Settings"
    assert html =~ "AI translation prompt"
    assert html =~ "Global prompt template"
    assert html =~ "Available placeholders"
    assert html =~ "{{source_text}}"
    assert html =~ "{{context}}"
    assert html =~ "S3 storage"
    assert html =~ locale.native_name
  end

  test "saves the global template and per-locale override" do
    {:ok, view, _html} = build_conn() |> live_isolated(SettingsLive, session: %{})

    view
    |> form("form[phx-submit='save_ai']",
      ai: %{
        "ai_prompt_template" => "New global template {{source_text}}",
        "ai_prompt_template_per_locale" => %{"de" => "Deutsche Vorlage {{source_text}}"}
      }
    )
    |> render_submit()

    assert Settings.prompt_template_for("de") == "Deutsche Vorlage {{source_text}}"
    assert Settings.prompt_template_for("fr") == "New global template {{source_text}}"
  end

  test "saves and encrypts the S3 secret" do
    {:ok, view, _html} = build_conn() |> live_isolated(SettingsLive, session: %{})

    view
    |> form("form[phx-submit='save_s3']",
      s3: %{
        "s3_access_key_id" => "AKIA123",
        "s3_secret_access_key" => "top-secret",
        "s3_bucket" => "assets",
        "s3_region" => "eu-central-1"
      }
    )
    |> render_submit()

    setting = Settings.get()
    assert setting.s3_access_key_id == "AKIA123"
    assert setting.s3_bucket == "assets"
    assert setting.s3_secret_access_key == "top-secret"
  end

  test "saves translation quality thresholds" do
    {:ok, view, html} = build_conn() |> live_isolated(SettingsLive, session: %{})

    assert html =~ "Translation quality warnings"

    view
    |> form("form[phx-submit='save_validations']",
      validations: %{
        "validation_length_warning_ratio" => "1.2",
        "validation_short_abs_error" => "9"
      }
    )
    |> render_submit()

    validations = Settings.validations()
    assert validations.length_warning_ratio == 1.2
    assert validations.short_abs_error == 9
  end
end
