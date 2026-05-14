defmodule ExLingoWeb.Translations.ContextLive do
  use ExLingoWeb, :live_view

  import ExLingo.Utils.ParamParsers, only: [parse_id_filter: 1]

  alias ExLingo.Translations
  alias ExLingo.Translations.Context

  def mount(%{"id" => id}, _session, socket) do
    socket =
      case get_context(id) do
        {:ok, %Context{} = context} -> assign(socket, :context, context)
        {:error, _, _reason} -> redirect(socket, to: "/ex_lingo/contexts")
      end

    {:ok, socket}
  end

  defp get_context(id) do
    case parse_id_filter(id) do
      {:ok, id} -> Translations.get_context(filter: [id: id])
      _ -> {:error, :id, :invalid}
    end
  end
end
