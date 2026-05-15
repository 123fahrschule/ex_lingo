defmodule ExLingoWeb.Translations.LocalesLive do
  use ExLingoWeb, :live_view

  alias ExLingo.Translations

  def mount(_params, _session, socket) do
    %{entries: locales, metadata: _entries_metadata} = Translations.list_locales()

    {:ok,
     socket
     |> assign(:locales, locales)}
  end

  def locale_gradient_class(locale) do
    case locale_colors(locale) |> length() do
      1 -> "locale-gradient locale-gradient--solid"
      2 -> "locale-gradient locale-gradient--split"
      _count -> "locale-gradient locale-gradient--tricolor"
    end
  end

  def locale_gradient_vars(locale) do
    [first, second, third] =
      locale
      |> locale_colors()
      |> then(fn colors -> colors ++ List.duplicate(List.first(colors), 3) end)
      |> Enum.take(3)

    "--locale-color-1: #{first}; --locale-color-2: #{second}; --locale-color-3: #{third};"
  end

  defp locale_colors(%{colors: colors}) when is_list(colors) and colors != [], do: colors
  defp locale_colors(_locale), do: ["#000000"]
end
