defmodule ExLingo.Translations.Contexts do
  @moduledoc """
  Gettext Contexts ExLingo subcontext
  """

  alias ExLingo.Translations.Context
  alias ExLingo.Translations.Contexts.Finders.{GetContext, ListAllContexts, ListContexts}
  alias ExLingo.Repo

  def list_contexts(params \\ []) do
    ListContexts.find(params)
  end

  def list_all_contexts(params \\ []) do
    ListAllContexts.find(params)
  end

  def get_context(params) do
    GetContext.find(params)
  end

  def create_context(attrs, opts \\ []) do
    %Context{}
    |> Context.changeset(attrs)
    |> Repo.get_repo().insert(Repo.opts(opts))
  end

  def update_context(%Context{} = context, attrs, opts \\ []) do
    context
    |> Context.changeset(attrs)
    |> Repo.get_repo().update(Repo.opts(opts))
  end

  def change_context(%Context{} = context, params \\ %{}) do
    Context.changeset(context, params)
  end
end
