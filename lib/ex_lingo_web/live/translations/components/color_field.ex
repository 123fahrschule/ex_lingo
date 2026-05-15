defmodule ExLingoWeb.Translations.Components.ColorField do
  @moduledoc false

  use ExLingoWeb, :component

  alias ExLingo.Utils.Colors

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :description, :string, default: nil

  def color_field(assigns) do
    assigns =
      assigns
      |> assign(:value, color_value(assigns.field.value))
      |> assign(:label, assigns.label || t("Color"))
      |> assign(
        :description,
        assigns.description || t("Used for badges and filters in translation tables.")
      )

    ~H"""
    <.form_item phx-hook="ExLingoColorPicker" id={"#{@field.id}-color-field"}>
      <.form_label field={@field}>{@label}</.form_label>
      <.form_control>
        <div class="grid gap-2 sm:grid-cols-[3.25rem_1fr]">
          <input
            type="color"
            id={"#{@field.id}-picker"}
            value={@value}
            data-color-picker
            aria-label={@label}
            class="h-9 w-full cursor-pointer rounded-md border border-input bg-background p-1 shadow-sm focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50"
          />
          <.input
            type="text"
            id={@field.id}
            name={@field.name}
            value={@value}
            pattern="#[0-9A-Fa-f]{6}"
            maxlength="7"
            data-color-text
            class="font-mono uppercase"
          />
        </div>
      </.form_control>
      <.form_description>
        {@description}
      </.form_description>
      <.form_message field={@field} translate={false} />
    </.form_item>
    """
  end

  defp color_value(value) when is_binary(value) do
    value = String.trim(value)

    if Regex.match?(~r/^#[0-9a-fA-F]{6}$/, value) do
      value
    else
      Colors.default_color()
    end
  end

  defp color_value(_value), do: Colors.default_color()
end
