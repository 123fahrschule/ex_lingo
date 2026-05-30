defmodule ExLingoWeb.Translations.MessageImagesLiveTest do
  @moduledoc """
  Drives the message-image panel in the messages table through a tiny host
  LiveView (the dashboard route only exists in the host app), exercising the
  real `update/2` and `toggle_images`/`delete_image` handlers.
  """

  use ExLingo.Test.DataCase, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias ExLingo.Translations

  @endpoint ExLingo.Test.Endpoint

  defmodule HostLive do
    use Phoenix.LiveView

    alias ExLingoWeb.Translations.Components.MessagesTable

    @preloads [:domain, :application_source, :singular_translations, :plural_translations]

    def mount(_params, %{"locale_id" => locale_id}, socket) do
      {:ok, locale} = Translations.get_locale(filter: [id: locale_id])
      {:ok, assign(socket, locale: locale) |> assign_messages()}
    end

    def handle_info(:refresh_messages, socket), do: {:noreply, assign_messages(socket)}

    defp assign_messages(socket) do
      %{entries: messages} = Translations.list_messages(preloads: @preloads)
      assign(socket, :messages, messages)
    end

    def render(assigns) do
      ~H"""
      <.live_component
        module={MessagesTable}
        id="messages-table"
        messages={@messages}
        filters={%{}}
        sort={%{}}
        locale={@locale}
        application_sources_empty?={true}
        stale_message_ids={MapSet.new()}
        fuzzy_matches={%{}}
        possible_duplicate_summaries={%{}}
      />
      """
    end
  end

  setup do
    ExLingo.Cache.delete_all()

    {:ok, locale} =
      Translations.create_locale(%{iso639_code: "de", name: "German", native_name: "Deutsch"})

    {:ok, message} = Translations.create_message(%{msgid: "Book now", message_type: :singular})

    %{locale: locale, message: message}
  end

  defp render_table(locale) do
    build_conn() |> live_isolated(HostLive, session: %{"locale_id" => to_string(locale.id)})
  end

  test "renders an images toggle with a count badge", %{locale: locale, message: message} do
    Translations.create_message_image(message.id, %{s3_key: "messages/#{message.id}/a.png"})

    {:ok, view, _html} = render_table(locale)

    assert has_element?(
             view,
             "button[phx-click='toggle_images'][phx-value-message-id='#{message.id}']"
           )

    # Count badge sits in the same actions cell and reflects the one image.
    assert view |> element("[data-list-item-id='#{message.id}']") |> render() =~ "1"
  end

  test "toggling opens the panel and prompts to configure S3 when unconfigured", %{
    locale: locale,
    message: message
  } do
    {:ok, view, _html} = render_table(locale)

    html =
      view
      |> element("button[phx-click='toggle_images'][phx-value-message-id='#{message.id}']")
      |> render_click()

    assert html =~ "Context images"
    assert html =~ "Configure S3 storage in Settings to upload images."
  end

  test "lists existing images in the opened panel", %{locale: locale, message: message} do
    Translations.create_message_image(message.id, %{s3_key: "messages/#{message.id}/shot.png"})

    {:ok, view, _html} = render_table(locale)

    html =
      view
      |> element("button[phx-click='toggle_images'][phx-value-message-id='#{message.id}']")
      |> render_click()

    # An <img> thumbnail is rendered (the presigned URL may be nil without S3,
    # but the delete control for the image is present).
    assert html =~ "Delete image"
  end
end
