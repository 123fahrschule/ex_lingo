defmodule ExLingoWeb.Components.Shared.SearchInput do
  @moduledoc """
  Simple search input component
  """

  use ExLingoWeb, :component

  attr :label, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, default: ""
  attr :class, :string, default: "min-w-72"
  attr :rest, :global

  def render(assigns) do
    ~H"""
    <div class="space-y-2">
      <Cognit.Label.label>
        {@label}
      </Cognit.Label.label>
      <div class="relative mt-1">
        <input
          type="search"
          name={@name}
          value={@value}
          class={[
            "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-body-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50",
            @class,
            "pr-10"
          ]}
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
