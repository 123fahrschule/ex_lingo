defmodule ExLingoWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use ExLingoWeb, :controller
      use ExLingoWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  require Logger

  def static_paths do
    ~w(assets fonts images favicon.ico favicon.svg robots.txt)
  end

  def html do
    quote do
      @moduledoc false
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def controller do
    phoenix_version =
      case Application.spec(:phoenix, :vsn) do
        vsn when is_list(vsn) ->
          List.to_string(vsn)

        _ ->
          Logger.warning(
            "Application.spec(:phoenix, :vsn) returned nil; defaulting ExLingo Phoenix integration to 1.8."
          )

          "1.8"
      end

    if String.starts_with?(phoenix_version, "1.7") do
      # Phoenix 1.7
      quote do
        use Phoenix.Controller, namespace: ExLingoWeb

        import Plug.Conn
        alias ExLingoWeb.Router.Helpers, as: Routes
        unquote(verified_routes())
      end
    else
      # Phoenix 1.8+
      quote do
        use Phoenix.Controller, formats: [:html, :json]

        import Plug.Conn
        alias ExLingoWeb.Router.Helpers, as: Routes
        unquote(verified_routes())

        plug :put_layout, html: {ExLingoWeb.LayoutView, :dashboard}
      end
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/ex_lingo_web/templates",
        namespace: ExLingoWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  defp view_helpers do
    quote do
      @endpoint Application.compile_env(:ex_lingo, :endpoint)

      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.Component

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import ExLingo.Utils.ModuleUtils
      import ExLingoWeb.I18n

      use Cognit

      alias ExLingoWeb.Components.Icons
      alias ExLingoWeb.Router.Helpers, as: Routes
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Application.compile_env(:ex_lingo, :endpoint),
        router: ExLingoWeb.Router,
        statics: ExLingoWeb.static_paths()

      def dashboard_path(%Phoenix.LiveView.Socket{} = socket),
        do: socket.router.__ex_lingo_dashboard_prefix__()

      def dashboard_path(%Plug.Conn{} = conn),
        do: conn.private.phoenix_router.__ex_lingo_dashboard_prefix__()

      def dashboard_path(%Phoenix.LiveView.Socket{} = socket, "/" <> path),
        do: dashboard_path(socket, path)

      def dashboard_path(%Phoenix.LiveView.Socket{} = socket, path) do
        path = ExLingoWeb.I18n.append_locale(path, ExLingoWeb.I18n.locale_from_socket(socket))
        socket.router.__ex_lingo_dashboard_prefix__() <> "/" <> path
      end

      def dashboard_path(%Plug.Conn{} = conn, "/" <> path), do: dashboard_path(conn, path)

      def dashboard_path(%Plug.Conn{} = conn, path) do
        path = ExLingoWeb.I18n.append_locale(path, ExLingoWeb.I18n.locale_from_conn(conn))

        unverified_path(
          conn,
          ExLingoWeb.Router,
          conn.private.phoenix_router.__ex_lingo_dashboard_prefix__() <> "/" <> path
        )
      end

      @doc """
      Returns `{:ok, dashboard_path}` for trusted dashboard-relative `to`
      arguments, `:error` otherwise. Used to guard query-param-driven redirects
      against open-redirect attacks.
      """
      def safe_dashboard_path(socket_or_conn, to) when is_binary(to) do
        cond do
          String.contains?(to, "://") -> :error
          String.starts_with?(to, "//") -> :error
          String.contains?(to, "..") -> :error
          true -> {:ok, dashboard_path(socket_or_conn, ensure_leading_slash(to))}
        end
      end

      def safe_dashboard_path(_socket_or_conn, _to), do: :error

      defp ensure_leading_slash("/" <> _ = path), do: path
      defp ensure_leading_slash(path), do: "/" <> path
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
