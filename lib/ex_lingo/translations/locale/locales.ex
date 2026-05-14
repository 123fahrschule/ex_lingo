defmodule ExLingo.Translations.Locales do
  @moduledoc """
  Locales ExLingo subcontext
  """

  alias ExLingo.Repo

  alias ExLingo.Translations.Locale
  alias ExLingo.Translations.Locale.Finders.{GetLocale, ListLocales}

  def list_locales(params \\ []) do
    ListLocales.find(params)
  end

  def get_locale(params \\ []) do
    GetLocale.find(params)
  end

  def create_locale(attrs, opts \\ []) do
    %Locale{} |> Locale.changeset(attrs) |> Repo.get_repo().insert(opts)
  end

  def update_locale(locale, attrs \\ %{}, opts \\ []) do
    Locale.changeset(locale, attrs)
    |> Repo.get_repo().update(opts)
  end
end
