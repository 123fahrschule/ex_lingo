defmodule ExLingoWeb.Router do
  use Phoenix.Router
  # deps/phoenix/lib/phoenix/router.ex:2:no_return Function call/2 has no local return.
  @dialyzer {:no_return, {:call, 2}}

  defmacro ex_lingo_dashboard(path \\ "/ex_lingo", opts \\ []) do
    opts =
      if Macro.quoted_literal?(opts) do
        Macro.prewalk(opts, &expand_alias(&1, __CALLER__))
      else
        opts
      end

    scope =
      quote bind_quoted: binding() do
        scope path, alias: false, as: false do
          {session_name, session_opts, route_opts} = ExLingoWeb.Router.__options__(opts)

          import Phoenix.Router
          import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

          live_session session_name, session_opts do
            get "/css-:md5", ExLingoWeb.Assets, :css, as: :ex_lingo_dashboard_asset
            get "/js-:md5", ExLingoWeb.Assets, :js, as: :ex_lingo_dashboard_asset
            get "/fonts/*path", ExLingoWeb.Assets, :font, as: :ex_lingo_dashboard_asset
            get "/favicon.ico", ExLingoWeb.Assets, :favicon, as: :ex_lingo_dashboard_asset
            get "/favicon.svg", ExLingoWeb.Assets, :favicon_svg, as: :ex_lingo_dashboard_asset

            scope "/", ExLingoWeb do
              live "/", Dashboard.DashboardLive, :index, route_opts
              live "/dashboard", Dashboard.DashboardLive, :index, route_opts

              scope "/application_sources", Translations do
                live "/", ApplicationSourcesLive, :index, route_opts
                live "/new", ApplicationSourceFormLive, :index, route_opts
                live "/:id", ApplicationSourceFormLive, :index, route_opts
              end

              scope "/domains", Translations do
                live "/", DomainsLive, :index, route_opts
                live "/:id", DomainLive, :index, route_opts
              end

              scope "/glossary", Translations do
                live "/", GlossaryLive, :index, route_opts
                live "/new", GlossaryEntryFormLive, :index, route_opts
                live "/:id", GlossaryEntryFormLive, :index, route_opts
              end

              scope "/possible_duplicates", Translations do
                live "/", PossibleDuplicatesLive, :index, route_opts
              end

              scope "/unclear_texts", Translations do
                live "/", UnclearTextsLive, :index, route_opts
              end

              scope "/locales", Translations do
                live "/", LocalesLive, :index, route_opts

                scope "/:locale_id" do
                  scope "/translations" do
                    live "/", TranslationsLive, :index, route_opts
                    live "/:message_id", TranslationFormLive, :show, route_opts
                  end
                end
              end
            end
          end
        end
      end

    quote do
      unquote(scope)

      unless Module.get_attribute(__MODULE__, :ex_lingo_dashboard_prefix) do
        @ex_lingo_dashboard_prefix ExLingoWeb.Router.internal_dashboard_scoped_path(path)
        def __ex_lingo_dashboard_prefix__, do: @ex_lingo_dashboard_prefix
      end
    end
  end

  defmacro ex_lingo_api(path \\ "/ex_lingo-api") do
    quote bind_quoted: binding() do
      pipeline :ex_lingo_api_pipeline do
        plug :accepts, ["json"]
        plug ExLingoWeb.APIAuthPlug
      end

      scope path, alias: false, as: false do
        scope "/", ExLingoWeb.Api do
          pipe_through :ex_lingo_api_pipeline
          get "/", ExLingoApiController, :index

          resources "/applications", ApplicationSourcesController, only: [:index, :update]
          resources "/domains", DomainsController, only: [:index, :update]
          resources "/locales", LocalesController, only: [:index, :update]
          resources "/messages", MessagesController, only: [:index, :update]

          resources "/singular_translations", SingularTranslationsController,
            only: [:index, :update]

          resources "/plural_translations", PluralTranslationsController, only: [:index, :update]
        end
      end
    end
  end

  defmacro internal_dashboard_scoped_path(path) do
    if Code.ensure_loaded?(Phoenix.VerifiedRoutes) do
      quote do
        Phoenix.Router.scoped_path(__MODULE__, unquote(path))
      end
    else
      quote do
        __MODULE__
        |> Module.get_attribute(:phoenix_top_scopes)
        |> Map.fetch!(:path)
        |> ExLingoWeb.Router.append_last_path(unquote(path))
        |> Enum.join("/")
        |> String.replace_prefix("", "/")
      end
    end
  end

  @spec append_last_path(list(), binary()) :: list()
  def append_last_path(paths, "/" <> path), do: append_last_path(paths, path)

  def append_last_path(paths, path) do
    if List.last(paths) == path do
      paths
    else
      paths ++ [path]
    end
  end

  defp expand_alias({:__aliases__, _, _} = alias, env),
    do: Macro.expand(alias, %{env | function: {:ex_lingo_dashboard, 2}})

  defp expand_alias(other, _env), do: other

  @doc false
  def __options__(options) do
    live_socket_path = Keyword.get(options, :live_socket_path, "/live")

    csp_nonce_assign_key =
      case options[:csp_nonce_assign_key] do
        nil -> nil
        key when is_atom(key) -> %{img: key, style: key, script: key}
        %{} = keys -> Map.take(keys, [:img, :style, :script])
      end

    on_mount =
      options
      |> Keyword.get(:on_mount)
      |> List.wrap()
      |> then(&[ExLingoWeb.I18n | &1])

    session_args = [
      csp_nonce_assign_key
    ]

    {
      options[:live_session_name] || :ex_lingo_dashboard,
      [
        session: {__MODULE__, :__session__, session_args},
        root_layout: {ExLingoWeb.LayoutView, :dashboard},
        on_mount: on_mount
      ],
      [
        private: %{live_socket_path: live_socket_path, csp_nonce_assign_key: csp_nonce_assign_key},
        as: :ex_lingo_dashboard
      ]
    }
  end

  @doc false
  def __session__(
        conn,
        csp_nonce_assign_key
      ) do
    nonce_keys = csp_nonce_assign_key || %{}

    %{
      "ex_lingo_locale" => ExLingoWeb.I18n.locale_from_conn(conn),
      "csp_nonces" => %{
        img: Map.get(conn.assigns, nonce_keys[:img]),
        style: Map.get(conn.assigns, nonce_keys[:style]),
        script: Map.get(conn.assigns, nonce_keys[:script])
      }
    }
  end
end
