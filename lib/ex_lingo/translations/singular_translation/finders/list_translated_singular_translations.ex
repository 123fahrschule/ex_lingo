defmodule ExLingo.Translations.SingularTranslations.Finders.ListTranslatedSingularTranslations do
  @moduledoc """
  Query module aka Finder responsible for listing translated singular translations
  """

  use ExLingo.Query,
    module: ExLingo.Translations.SingularTranslation,
    binding: :singular_translation

  alias ExLingo.Repo

  def find do
    base()
    |> translated_query()
    |> Repo.get_repo().all(Repo.opts())
  end

  defp translated_query(query) do
    from(st in query,
      where: not is_nil(st.translated_text) and fragment("btrim(?) <> ''", st.translated_text)
    )
  end
end
