defmodule ExLingoWeb.Assets do
  # Plug to serve dependency-specific assets for the dashboard.
  @moduledoc false
  import Plug.Conn

  phoenix_js_paths =
    for app <- [:phoenix, :phoenix_html, :phoenix_live_view] do
      path = Application.app_dir(app, ["priv", "static", "#{app}.js"])
      Module.put_attribute(__MODULE__, :external_resource, path)
      path
    end

  css_path = Path.join(__DIR__, "../../../dist/css/app.css")
  @external_resource css_path
  @css File.read!(css_path)

  font_root = Path.join(__DIR__, "../../../priv/static/fonts")

  @font_paths MapSet.new(
                for path <- Path.wildcard(Path.join(font_root, "**/*.woff2")) do
                  Module.put_attribute(__MODULE__, :external_resource, path)

                  path
                  |> Path.relative_to(font_root)
                  |> Path.split()
                  |> Path.join()
                end
              )

  js_path = Path.join(__DIR__, "../../../dist/js/app.js")
  @external_resource js_path

  favicon_path = Path.join(__DIR__, "../../../priv/static/favicon.ico")
  @external_resource favicon_path
  @favicon File.read!(favicon_path)

  favicon_svg_path = Path.join(__DIR__, "../../../priv/static/favicon.svg")
  @external_resource favicon_svg_path
  @favicon_svg File.read!(favicon_svg_path)

  @js """
  #{for path <- phoenix_js_paths, do: path |> File.read!() |> String.replace("//# sourceMappingURL=", "// ")}
  #{File.read!(js_path)}
  """

  @hashes %{
    :css => Base.encode16(:crypto.hash(:md5, @css), case: :lower),
    :js => Base.encode16(:crypto.hash(:md5, @js), case: :lower)
  }

  def init(asset) when asset in [:css, :js, :font, :favicon, :favicon_svg], do: asset

  def call(%{params: %{"path" => path_segments}} = conn, :font)
      when is_list(path_segments) do
    font_path = Path.join(path_segments)

    if valid_font_path?(path_segments) do
      serve_font(conn, font_path)
    else
      not_found(conn)
    end
  end

  def call(conn, :font), do: not_found(conn)

  def call(conn, asset) do
    {contents, content_type} = contents_and_type(asset)

    conn
    |> put_resp_header("content-type", content_type)
    |> put_resp_header("cache-control", "public, max-age=31536000")
    |> put_private(:plug_skip_csrf_protection, true)
    |> send_resp(200, contents)
    |> halt()
  end

  defp contents_and_type(:css), do: {@css, "text/css"}
  defp contents_and_type(:js), do: {@js, "text/javascript"}
  defp contents_and_type(:favicon), do: {@favicon, "image/x-icon"}
  defp contents_and_type(:favicon_svg), do: {@favicon_svg, "image/svg+xml"}

  defp serve_font(conn, font_path) do
    if MapSet.member?(@font_paths, font_path) do
      font_file = Path.join([priv_static_fonts_path(), font_path])

      case File.read(font_file) do
        {:ok, contents} ->
          conn
          |> put_resp_header("content-type", "font/woff2")
          |> put_resp_header("cache-control", "public, max-age=31536000")
          |> put_private(:plug_skip_csrf_protection, true)
          |> send_resp(200, contents)
          |> halt()

        {:error, _reason} ->
          not_found(conn)
      end
    else
      not_found(conn)
    end
  end

  defp priv_static_fonts_path do
    case :code.priv_dir(:ex_lingo) do
      {:error, _reason} -> Path.join(__DIR__, "../../../priv/static/fonts")
      priv_dir -> Path.join(to_string(priv_dir), "static/fonts")
    end
  end

  defp valid_font_path?(path_segments) do
    Enum.all?(path_segments, &(&1 not in ["", ".", ".."])) and
      Path.extname(Path.join(path_segments)) == ".woff2"
  end

  defp not_found(conn) do
    conn
    |> put_private(:plug_skip_csrf_protection, true)
    |> send_resp(404, "Not found")
    |> halt()
  end

  @doc """
  Returns the current hash for the given `asset`.
  """
  def current_hash(:css), do: @hashes.css
  def current_hash(:js), do: @hashes.js
end
