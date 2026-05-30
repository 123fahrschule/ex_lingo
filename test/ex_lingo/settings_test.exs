defmodule ExLingo.SettingsTest do
  use ExLingo.Test.DataCase, async: false

  alias ExLingo.Settings
  alias ExLingo.Settings.Setting

  setup do
    ExLingo.Cache.delete_all()
    :ok
  end

  describe "get/0" do
    test "lazily creates the row seeded with the default prompt template" do
      setting = Settings.get()

      assert %Setting{} = setting
      assert setting.id == 1
      assert setting.ai_prompt_template =~ "driving school domain"
      assert setting.ai_prompt_template =~ "{{source_text}}"
      assert setting.ai_prompt_template =~ "{{context}}"
      assert setting.ai_prompt_template_per_locale == %{}
      assert setting.s3_prefix == "/"
    end

    test "returns the same single row on repeated calls" do
      first = Settings.get()
      second = Settings.get()

      assert first.id == second.id
    end
  end

  describe "update/1" do
    test "persists the global template and invalidates the cache" do
      _seed = Settings.get()

      {:ok, updated} = Settings.update(%{"ai_prompt_template" => "Custom template"})
      assert updated.ai_prompt_template == "Custom template"

      assert Settings.get().ai_prompt_template == "Custom template"
    end

    test "drops blank per-locale overrides" do
      {:ok, updated} =
        Settings.update(%{
          "ai_prompt_template_per_locale" => %{"de" => "Deutsche Vorlage", "fr" => "  "}
        })

      assert updated.ai_prompt_template_per_locale == %{"de" => "Deutsche Vorlage"}
    end

    test "encrypts the S3 secret at rest and decrypts it on load" do
      {:ok, updated} = Settings.update(%{"s3_secret_access_key" => "super-secret"})

      assert Setting.s3_secret_present?(updated)
      assert updated.s3_secret_access_key == "super-secret"

      # The raw column holds ciphertext, never the plaintext.
      [stored] =
        ExLingo.Test.Repo.all(from(s in "ex_lingo_settings", select: s.s3_secret_access_key))

      assert is_binary(stored)
      refute stored == "super-secret"

      # A fresh load through the schema transparently decrypts.
      assert Settings.get().s3_secret_access_key == "super-secret"
    end

    test "stores a custom S3 folder prefix and falls back to the bucket root when blank" do
      {:ok, with_prefix} = Settings.update(%{"s3_prefix" => "  ex_lingo/  "})
      assert with_prefix.s3_prefix == "ex_lingo/"

      {:ok, blanked} = Settings.update(%{"s3_prefix" => "   "})
      assert blanked.s3_prefix == "/"
    end

    test "keeps the stored secret when the secret field is left blank" do
      {:ok, _} = Settings.update(%{"s3_secret_access_key" => "super-secret"})

      {:ok, updated} =
        Settings.update(%{"s3_secret_access_key" => "", "s3_bucket" => "my-bucket"})

      assert updated.s3_bucket == "my-bucket"
      assert updated.s3_secret_access_key == "super-secret"
    end
  end

  describe "prompt_template_for/1" do
    test "prefers the per-locale override" do
      {:ok, _} =
        Settings.update(%{
          "ai_prompt_template" => "Global template",
          "ai_prompt_template_per_locale" => %{"de" => "German template"}
        })

      assert Settings.prompt_template_for("de") == "German template"
    end

    test "falls back to the global template" do
      {:ok, _} =
        Settings.update(%{
          "ai_prompt_template" => "Global template",
          "ai_prompt_template_per_locale" => %{"de" => "German template"}
        })

      assert Settings.prompt_template_for("fr") == "Global template"
    end

    test "returns nil when the global template is blank" do
      {:ok, _} =
        Settings.update(%{
          "ai_prompt_template" => "",
          "ai_prompt_template_per_locale" => %{}
        })

      assert Settings.prompt_template_for("fr") == nil
    end
  end
end
