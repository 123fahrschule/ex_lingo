defmodule ExLingoWeb.Translations.Components.FiltersBar do
  @moduledoc """
  Messages filters bar component
  """

  use ExLingoWeb, :live_component

  alias ExLingo.Translations

  alias ExLingoWeb.Components.Shared.{SearchInput, Select, Toggle}

  def update(assigns, socket) do
    %{entries: domains, metadata: _domains_metadata} = Translations.list_domains()

    default_assigns = %{
      domains: domains,
      filters: %{domain: nil}
    }

    {:ok, assign(socket, Map.merge(default_assigns, assigns))}
  end
end
