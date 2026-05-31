defmodule ExLingoWeb.Translations.InlineTranslationEditingTest do
  @moduledoc """
  Integration tests for inline translation editing (Briefing 05).

  The dashboard is mounted by a host application router, so there is no route
  available in the test endpoint. We therefore drive the inline editor
  components through a tiny host LiveView using `live_isolated/3`, exercising the
  real `update/2` and event handlers (auto-save on blur, upsert, validation).
  """

  use ExLingo.Test.DataCase, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias ExLingo.Translations

  @endpoint ExLingo.Test.Endpoint

  defmodule HostLive do
    use Phoenix.LiveView

    alias ExLingo.Translations
    alias ExLingoWeb.Translations.{PluralTranslationForm, SingularTranslationForm}

    @preloads [:domain, :singular_translations, :plural_translations]

    def mount(_params, %{"message_id" => message_id, "locale_id" => locale_id}, socket) do
      {:ok, message} = Translations.get_message(filter: [id: message_id], preloads: @preloads)
      {:ok, locale} = Translations.get_locale(filter: [id: locale_id])

      {:ok, assign(socket, message: message, locale: locale)}
    end

    def render(assigns) do
      ~H"""
      <div data-glossary-scope>
        <div data-glossary-source>{@message.msgid}</div>
        <.live_component
          :if={@message.message_type == :singular}
          module={SingularTranslationForm}
          id="form"
          message={@message}
          locale={@locale}
          translation={
            SingularTranslationForm.transient_translation(
              @message,
              @locale,
              @message.singular_translations
            )
          }
          filters={%{}}
        />
        <.live_component
          :if={@message.message_type == :plural}
          module={PluralTranslationForm}
          id="form"
          message={@message}
          locale={@locale}
          translations={
            PluralTranslationForm.transient_translations(
              @message,
              @locale,
              @message.plural_translations
            )
          }
          filters={%{}}
        />
      </div>
      """
    end
  end

  setup do
    ExLingo.Cache.delete_all()

    {:ok, locale} =
      Translations.create_locale(%{
        iso639_code: "de",
        name: "German",
        native_name: "Deutsch",
        plurals_header: "nplurals=2; plural=(n != 1);"
      })

    %{locale: locale}
  end

  describe "singular inline editing" do
    test "renders an inline input bound to the existing translation", %{locale: locale} do
      message = create_message("Cancel", :singular)

      {:ok, _translation} =
        Translations.create_singular_translation(%{
          message_id: message.id,
          locale_id: locale.id,
          original_text: "Cancel",
          translated_text: "Abbrechen"
        })

      {:ok, _view, html} = mount_host(message, locale)

      assert html =~ ~s(name="translated_text")
      assert html =~ "data-inline-input"
      assert html =~ "Abbrechen"
    end

    test "auto-saves on blur and creates a missing translation (upsert)", %{locale: locale} do
      message = create_message("Save", :singular)

      {:ok, view, _html} = mount_host(message, locale)

      view
      |> element(~s(form[phx-change="validate"]))
      |> render_change(%{"translated_text" => "Speichern"})

      view |> element(~s(textarea[data-inline-input])) |> render_blur()

      assert {:ok, translation} =
               Translations.get_singular_translation(
                 filter: [message_id: message.id, locale_id: locale.id]
               )

      assert translation.translated_text == "Speichern"
    end

    test "auto-saves on blur and updates an existing translation", %{locale: locale} do
      message = create_message("Delete", :singular)

      {:ok, _translation} =
        Translations.create_singular_translation(%{
          message_id: message.id,
          locale_id: locale.id,
          original_text: "Delete",
          translated_text: "Alt"
        })

      {:ok, view, _html} = mount_host(message, locale)

      view
      |> element(~s(form[phx-change="validate"]))
      |> render_change(%{"translated_text" => "Löschen"})

      view |> element(~s(textarea[data-inline-input])) |> render_blur()

      assert {:ok, translation} =
               Translations.get_singular_translation(
                 filter: [message_id: message.id, locale_id: locale.id]
               )

      assert translation.translated_text == "Löschen"
    end

    test "shows a validation hint when the translation is much longer than the source", %{
      locale: locale
    } do
      message = create_message("OK", :singular)

      {:ok, view, _html} = mount_host(message, locale)

      html =
        view
        |> element(~s(form[phx-change="validate"]))
        |> render_change(%{
          "translated_text" => "Ein wirklich sehr viel zu langer Text der die UI sprengt"
        })

      assert html =~ "longer than original"
    end
  end

  describe "plural inline editing" do
    test "renders one stacked input per plural form", %{locale: locale} do
      message = create_message("%{count} item", :plural)

      {:ok, _view, html} = mount_host(message, locale)

      assert html =~ "Form 1"
      assert html =~ "Form 2"
      assert html =~ "data-inline-input"
    end

    test "auto-saves a single plural form on blur (upsert)", %{locale: locale} do
      message = create_message("%{count} item", :plural)

      {:ok, view, _html} = mount_host(message, locale)

      view
      |> element(~s(form[phx-value-index="1"]))
      |> render_change(%{"translated_text" => "%{count} Einträge", "index" => "1"})

      view |> element(~s(textarea[phx-value-index="1"])) |> render_blur(%{"index" => "1"})

      %{entries: translations} =
        Translations.list_plural_translations(
          filter: [message_id: message.id, locale_id: locale.id]
        )

      form_one = Enum.find(translations, &(&1.nplural_index == 1))

      assert form_one
      assert form_one.translated_text == "%{count} Einträge"
    end

    test "auto-saves on blur and updates an existing plural form", %{locale: locale} do
      message = create_message("%{count} item", :plural)

      {:ok, _existing} =
        Translations.create_plural_translation(%{
          message_id: message.id,
          locale_id: locale.id,
          nplural_index: 1,
          original_text: "%{count} items",
          translated_text: "Alt"
        })

      {:ok, view, _html} = mount_host(message, locale)

      view
      |> element(~s(form[phx-value-index="1"]))
      |> render_change(%{"translated_text" => "%{count} Einträge", "index" => "1"})

      view |> element(~s(textarea[phx-value-index="1"])) |> render_blur(%{"index" => "1"})

      %{entries: translations} =
        Translations.list_plural_translations(
          filter: [message_id: message.id, locale_id: locale.id]
        )

      form_one = Enum.find(translations, &(&1.nplural_index == 1))

      assert form_one.translated_text == "%{count} Einträge"
      assert Enum.count(translations, &(&1.nplural_index == 1)) == 1
    end
  end

  defp create_message(msgid, type) do
    {:ok, message} = Translations.create_message(%{msgid: msgid, message_type: type})
    message
  end

  defp mount_host(message, locale) do
    build_conn()
    |> live_isolated(HostLive,
      session: %{"message_id" => message.id, "locale_id" => locale.id}
    )
  end
end
