defmodule ExLingoWeb.LayoutView do
  @moduledoc false
  use ExLingoWeb, :html

  import Cognit.Components.AppSideNav

  embed_templates "../templates/layouts/*"

  def render(_, assigns), do: dashboard(assigns)

  def csp_nonce(conn, type) when type in [:script, :style, :img] do
    csp_nonce_assign_key = conn.private.csp_nonce_assign_key[type]
    conn.assigns[csp_nonce_assign_key]
  end

  def live_socket_path(conn) do
    [Enum.map(conn.script_name, &["/" | &1]) | conn.private.live_socket_path]
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
