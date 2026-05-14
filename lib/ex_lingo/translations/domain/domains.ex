defmodule ExLingo.Translations.Domains do
  @moduledoc """
  Gettext domains ExLingo subcontext
  """

  alias ExLingo.Repo

  alias ExLingo.Translations.Domain
  alias ExLingo.Translations.Domains.Finders.{GetDomain, ListAllDomains, ListDomains}

  def list_domains(params \\ []) do
    ListDomains.find(params)
  end

  def list_all_domains(params \\ []) do
    ListAllDomains.find(params)
  end

  def get_domain(params) do
    GetDomain.find(params)
  end

  def create_domain(attrs, opts \\ []) do
    %Domain{}
    |> Domain.changeset(attrs)
    |> Repo.get_repo().insert(opts)
  end
end
