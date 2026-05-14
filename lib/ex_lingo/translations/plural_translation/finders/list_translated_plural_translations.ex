defmodule ExLingo.Translations.PluralTranslations.Finders.ListTranslatedPluralTranslations do
  @moduledoc """
  Query module aka Finder responsible for listing translated plural translations
  """

  use ExLingo.Query,
    module: ExLingo.Translations.PluralTranslation,
    binding: :plural_translation

  alias ExLingo.Repo

  def find do
    base()
    |> translated_query()
    |> Repo.get_repo().all(Repo.opts())
  end

  defp translated_query(query) do
    from(pt in query,
      where: not is_nil(pt.translated_text) and pt.translated_text != ""
    )
  end
end
