defmodule ExLingo.Translations do
  @moduledoc """
  Main ExLingo Translations context
  """

  alias ExLingo.Translations.{
    Domains,
    GlossaryEntries,
    Locales,
    Messages,
    PossibleDuplicateTranslations,
    PluralTranslations,
    SingularTranslations
  }

  # DOMAINS
  defdelegate list_domains(params \\ []), to: Domains
  defdelegate list_all_domains(params \\ []), to: Domains
  defdelegate get_domain(params \\ []), to: Domains
  defdelegate create_domain(attrs, opts \\ []), to: Domains
  defdelegate update_domain(domain, attrs, opts \\ []), to: Domains
  defdelegate change_domain(domain, params \\ %{}), to: Domains

  # GLOSSARY ENTRIES
  defdelegate list_glossary_entries(params \\ []), to: GlossaryEntries
  defdelegate list_all_glossary_entries(params \\ []), to: GlossaryEntries
  defdelegate list_matching_glossary_entries(params \\ []), to: GlossaryEntries
  defdelegate get_glossary_entry(params), to: GlossaryEntries
  defdelegate create_glossary_entry(attrs, opts \\ []), to: GlossaryEntries
  defdelegate update_glossary_entry(glossary_entry, attrs, opts \\ []), to: GlossaryEntries
  defdelegate delete_glossary_entry(glossary_entry, opts \\ []), to: GlossaryEntries
  defdelegate change_glossary_entry(glossary_entry, params \\ %{}), to: GlossaryEntries

  # MESSAGES
  defdelegate list_messages(params \\ []), to: Messages
  defdelegate list_all_messages(params \\ []), to: Messages
  defdelegate get_message(params \\ []), to: Messages
  defdelegate get_messages_count(), to: Messages
  defdelegate create_message(attrs, opts \\ []), to: Messages
  defdelegate update_message(message, attrs, opts \\ []), to: Messages
  defdelegate mark_message_context_unclear(message, opts \\ []), to: Messages
  defdelegate clear_context_reviews_for_key(attrs, opts \\ []), to: Messages
  defdelegate list_context_review_messages(params \\ []), to: Messages
  defdelegate delete_message(message_id), to: Messages
  defdelegate delete_messages(message_ids), to: Messages
  defdelegate merge_messages(from_message_id, to_message_id), to: Messages

  # MESSAGE IMAGES
  defdelegate list_message_images(message_id), to: Messages, as: :list_images
  defdelegate get_message_image(image_id), to: Messages, as: :get_image
  defdelegate create_message_image(message_id, attrs, opts \\ []), to: Messages, as: :create_image
  defdelegate delete_message_image(image_id, opts \\ []), to: Messages, as: :delete_image
  defdelegate message_image_counts(message_ids), to: Messages, as: :image_counts
  defdelegate move_message_images(from_id, to_id, opts \\ []), to: Messages, as: :move_images

  # LOCALES
  defdelegate list_locales(params \\ []), to: Locales
  defdelegate get_locale(params \\ []), to: Locales
  defdelegate update_locale(locale, attrs, opts \\ []), to: Locales
  defdelegate create_locale(attrs, opts \\ []), to: Locales

  # TRANSLATIONS
  defdelegate list_plural_translations(params \\ []), to: PluralTranslations
  defdelegate get_plural_translation(params), to: PluralTranslations
  defdelegate create_plural_translation(attrs, opts \\ []), to: PluralTranslations
  defdelegate update_plural_translation(translation, attrs, opts \\ []), to: PluralTranslations

  defdelegate list_singular_translations(params \\ []), to: SingularTranslations
  defdelegate get_singular_translation(params), to: SingularTranslations
  defdelegate create_singular_translation(attrs, opts \\ []), to: SingularTranslations

  defdelegate update_singular_translation(translation, attrs, opts \\ []),
    to: SingularTranslations

  # POSSIBLE DUPLICATES
  defdelegate list_possible_duplicate_translations(params \\ []),
    to: PossibleDuplicateTranslations,
    as: :list

  defdelegate possible_duplicate_translation_summaries(params \\ []),
    to: PossibleDuplicateTranslations,
    as: :summaries_by_message

  defdelegate possible_duplicate_translations_for_message(params),
    to: PossibleDuplicateTranslations,
    as: :candidates_for_message
end
