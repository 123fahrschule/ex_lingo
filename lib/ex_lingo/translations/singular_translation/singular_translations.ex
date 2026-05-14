defmodule ExLingo.Translations.SingularTranslations do
  @moduledoc """
  Singular translations ExLingo subcontext
  """

  alias ExLingo.Translations.SingularTranslations.Finders.{
    GetSingularTranslation,
    ListSingularTranslations
  }

  alias ExLingo.Cache
  alias ExLingo.Repo
  alias ExLingo.Translations.SingularTranslation

  def list_singular_translations(params \\ []) do
    ListSingularTranslations.find(params)
  end

  def get_singular_translation(params \\ []) do
    GetSingularTranslation.find(params)
  end

  def create_singular_translation(attrs, opts \\ []) do
    attrs
    |> then(&SingularTranslation.changeset(%SingularTranslation{}, &1))
    |> Repo.get_repo().insert(Repo.opts(opts))
    |> case do
      {:ok, singular_translation} ->
        cache_key =
          Cache.generate_cache_key("singular_translation",
            filter: [
              locale_id: singular_translation.locale_id,
              message_id: singular_translation.message_id
            ]
          )

        Cache.put(cache_key, singular_translation)
        {:ok, singular_translation}

      error ->
        error
    end
  end

  def update_singular_translation(translation, attrs, opts \\ []) do
    SingularTranslation.changeset(translation, attrs)
    |> Repo.get_repo().update(Repo.opts(opts))
    |> case do
      {:ok, translation} ->
        cache_key =
          Cache.generate_cache_key("singular_translation",
            filter: [
              locale_id: translation.locale_id,
              message_id: translation.message_id
            ]
          )

        Cache.put(cache_key, translation)

        {:ok, translation}

      error ->
        error
    end
  end
end
