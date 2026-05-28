defmodule ExLingoWeb.Translations.GlossaryEntriesTable do
  @moduledoc """
  Glossary entries table component.
  """

  use ExLingoWeb, :live_component
  require Logger

  alias ExLingo.Translations

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("edit_glossary_entry", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: dashboard_path(socket, "/glossary/#{id}"))}
  end

  def handle_event("delete_glossary_entry", %{"id" => id}, socket) do
    with {:ok, glossary_entry} <- Translations.get_glossary_entry(filter: [id: id]),
         {:ok, _deleted} <- Translations.delete_glossary_entry(glossary_entry) do
      send(self(), :refresh_glossary_entries)
      {:noreply, socket}
    else
      error ->
        Logger.error("failed to delete glossary entry #{inspect(id)}: #{inspect(error)}")
        {:noreply, put_flash(socket, :error, t("Failed to delete glossary entry."))}
    end
  end

  def scope_label(glossary_entry) do
    [
      relation_label(t("Domain"), glossary_entry.domain),
      relation_label(t("Application"), glossary_entry.application_source)
    ]
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> t("Global")
      labels -> Enum.join(labels, " / ")
    end
  end

  defp relation_label(_label, nil), do: nil
  defp relation_label(_label, %Ecto.Association.NotLoaded{}), do: nil
  defp relation_label(label, %{name: name}), do: "#{label}: #{name}"
end
