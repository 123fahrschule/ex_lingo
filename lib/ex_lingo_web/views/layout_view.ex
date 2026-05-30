defmodule ExLingoWeb.LayoutView do
  @moduledoc false
  use ExLingoWeb, :html

  import Cognit.Components.AppSideNav

  embed_templates "../templates/layouts/*"

  def render(_, assigns), do: dashboard(assigns)

  @doc """
  Restores the sidebar expanded/collapsed state from the `sidebar_state` cookie
  the Cognit sidebar hook writes, so the choice survives reloads and navigation.
  """
  def sidebar_state(conn) do
    cookies = Map.get(conn, :cookies)

    case is_map(cookies) && Map.get(cookies, "sidebar_state") do
      state when state in ["expanded", "collapsed"] -> state
      _other -> "expanded"
    end
  end

  def csp_nonce(conn, type) when type in [:script, :style, :img] do
    private = Map.get(conn, :private) || %{}
    assigns = Map.get(conn, :assigns) || %{}
    csp_nonce_assign_key = get_in(private, [:csp_nonce_assign_key, type])

    Map.get(assigns, csp_nonce_assign_key)
  end

  def live_socket_path(conn) do
    private = Map.get(conn, :private) || %{}
    live_socket_path = Map.get(private, :live_socket_path) || []

    [Enum.map(conn.script_name, &["/" | &1]) | live_socket_path]
  end

  def asset_path(conn, :favicon), do: dashboard_path(conn, "/favicon.ico")
  def asset_path(conn, :favicon_svg), do: dashboard_path(conn, "/favicon.svg")

  def asset_path(conn, asset) when asset in [:css, :js] do
    hash = ExLingoWeb.Assets.current_hash(asset)

    prefix = dashboard_path(conn)

    Phoenix.VerifiedRoutes.unverified_path(
      conn,
      conn.private.phoenix_router,
      "#{prefix}/#{asset}-#{hash}"
    )
  end
end
