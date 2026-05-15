defmodule ExLingoWeb.Translations.Components.FiltersBar do
  @moduledoc """
  Messages filters bar component
  """

  use ExLingoWeb, :live_component

  alias ExLingo.Translations

  alias ExLingoWeb.Components.Shared.{SearchInput, Select, Toggle}

  def update(assigns, socket) do
    %{entries: contexts, metadata: _contexts_metadata} = Translations.list_contexts()
    %{entries: domains, metadata: _domains_metadata} = Translations.list_domains()

    %{entries: application_sources, metadata: _application_sources_metadata} =
      Translations.list_application_sources()

    default_assigns = %{
      contexts: contexts,
      domains: domains,
      application_sources: application_sources,
      filters: %{
        domain: nil,
        context: nil,
        application_source: nil
      }
    }

    {:ok, assign(socket, Map.merge(default_assigns, assigns))}
  end
end
