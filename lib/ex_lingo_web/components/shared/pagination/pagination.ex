defmodule ExLingoWeb.Components.Shared.Pagination do
  @moduledoc """
  Thin wrapper around the Cognit pagination component for Scrivener page metadata.
  """

  use ExLingoWeb, :component

  attr :metadata, :map,
    required: true,
    doc: "Scrivener page with :page_number, :total_pages, :total_entries, :page_size"

  attr :on_page_change, :any, required: true, doc: "Event to trigger when changing pages"
  attr :id, :string, default: "ex-lingo-pagination"
  attr :page_sizes, :list, default: [10, 20, 30, 40, 50, 100]

  def render(assigns) do
    %{
      page_number: page,
      total_pages: total_pages,
      total_entries: total_entries,
      page_size: page_size
    } = assigns.metadata

    assigns =
      assign(assigns,
        page: page,
        total_pages: total_pages,
        total_entries: total_entries,
        page_size: page_size
      )

    ~H"""
    <.pagination
      id={@id}
      page={@page}
      page_size={@page_size}
      page_sizes={@page_sizes}
      total_pages={@total_pages}
      total_entries={@total_entries}
      on_change={@on_page_change}
    />
    """
  end
end
