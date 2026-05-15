defmodule ExLingoWeb.Components.Shared.Pagination do
  @moduledoc """
  A component for rendering pagination controls with support for page navigation.

  This component displays a pagination interface with previous/next buttons and page numbers.
  It handles edge cases like ellipses for many pages and proper accessibility attributes.
  """

  use ExLingoWeb, :component

  # Simple type definitions for pagination entries
  @type page_entry :: {:page, integer()}
  @type ellipsis_entry :: :ellipsis

  attr :metadata, :map,
    required: true,
    doc: "Pagination metadata with :page_number and :total_pages keys"

  attr :on_page_change, :any, required: true, doc: "Event to trigger when changing pages"

  attr :id, :string, default: "ex-lingo-pagination"

  attr :page_sizes, :list,
    default: [10, 20, 30, 40, 50, 100],
    doc: "Selectable page sizes"

  attr :surrounding_pages_number, :integer,
    default: 4,
    doc: "Number of page links to show around current page"

  def render(
        %{
          metadata: %{
            page_number: p_num,
            total_pages: total_pages,
            total_entries: total_entries,
            page_size: page_size
          }
        } = assigns
      )
      when is_integer(p_num) and p_num > 0 and is_integer(total_pages) and total_pages > 0 do
    assigns =
      assign(assigns,
        current_page: p_num,
        total_pages: total_pages,
        total_entries: total_entries,
        page_size: page_size
      )

    ~H"""
    <.pagination
      id={@id}
      page={@current_page}
      page_size={@page_size}
      page_sizes={@page_sizes}
      total_pages={@total_pages}
      total_entries={@total_entries}
      on_change={@on_page_change}
    />
    """
  end

  def render(assigns) do
    ~H"""
    <div />
    """
  end

  @doc """
  Calculates the sequence of page numbers and ellipses to display in the pagination component.

  Returns a list of entries, where each entry is either:
  - {:page, n} - A page number to display
  - :ellipsis - An ellipsis indicating skipped pages
  """
  @spec calculate_pages(integer(), integer(), integer()) :: [page_entry | ellipsis_entry]
  def calculate_pages(_current_page, total_pages, _surrounding) when total_pages < 1, do: []

  def calculate_pages(_current_page, 1, _surrounding), do: [{:page, 1}]

  def calculate_pages(current_page, total_pages, surrounding) do
    current_page = current_page |> min(total_pages) |> max(1)

    # Define the middle range that always includes the current page
    start_middle = max(current_page - surrounding, 2)
    end_middle = min(current_page + surrounding, total_pages - 1)

    # Generate the complete list of entries in a single pass
    []
    |> add_first_page()
    |> add_start_ellipsis(start_middle)
    |> add_middle_pages(start_middle, end_middle)
    |> add_end_ellipsis(end_middle, total_pages)
    |> add_last_page(total_pages)
  end

  defp add_first_page(list), do: list ++ [{:page, 1}]

  defp add_start_ellipsis(list, start_middle) when start_middle > 2, do: list ++ [:ellipsis]
  defp add_start_ellipsis(list, _), do: list

  defp add_middle_pages(list, start_middle, end_middle) when start_middle <= end_middle do
    middle_pages = Enum.map(start_middle..end_middle, &{:page, &1})
    list ++ middle_pages
  end

  defp add_middle_pages(list, _, _), do: list

  defp add_end_ellipsis(list, end_middle, total_pages) when end_middle < total_pages - 1,
    do: list ++ [:ellipsis]

  defp add_end_ellipsis(list, _, _), do: list

  # Don't add last page if total_pages is 1
  defp add_last_page(list, 1), do: list
  defp add_last_page(list, total_pages), do: list ++ [{:page, total_pages}]
end
