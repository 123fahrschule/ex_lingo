defmodule ExLingoWeb.Components.Shared.SearchInput do
  @moduledoc """
  Simple search input component
  """

  use ExLingoWeb, :component

  attr :label, :string, required: true
  attr :name, :any
  attr :value, :any
  attr :rest, :global

  def render(assigns) do
    ~H"""
    <div class="space-y-2">
      <Cognit.Label.label>
        {@label}
      </Cognit.Label.label>
      <div class="relative mt-1">
        <.input
          name={@name}
          value={@value}
          class="min-w-72 pr-10"
          {@rest}
        />
        <span class="absolute inset-y-0 right-0 flex items-center pr-2 ml-3 pointer-events-none">
          <.icon name="search" size="xs" class="text-muted-foreground" decorative />
        </span>
      </div>
    </div>
    """
  end
end
