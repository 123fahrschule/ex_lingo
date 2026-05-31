defmodule ExLingo.AI.Translations.SuggestionRequest do
  @moduledoc """
  Normalized request passed from ExLingo to AI translation suggestion providers.
  """

  alias ExLingo.Translations.GlossaryEntry

  @type current_translation :: %{
          optional(:id) => term(),
          optional(:original_text) => String.t() | nil,
          optional(:translated_text) => String.t() | nil,
          optional(:nplural_index) => integer()
        }

  @type message_metadata :: %{
          optional(:message_id) => term(),
          optional(:domain_id) => term(),
          optional(:context) => String.t() | nil
        }

  @type t :: %__MODULE__{
          source_locale: String.t(),
          target_locale: String.t(),
          target_locale_name: String.t() | nil,
          source_text: String.t(),
          message_type: :singular | :plural,
          message_metadata: message_metadata(),
          current_translation: current_translation(),
          glossary_entries: [GlossaryEntry.t()],
          plural_form_index: integer() | nil,
          plural_examples: String.t() | nil,
          model: String.t() | nil
        }

  defstruct source_locale: nil,
            target_locale: nil,
            target_locale_name: nil,
            source_text: nil,
            message_type: nil,
            message_metadata: %{},
            current_translation: %{},
            glossary_entries: [],
            plural_form_index: nil,
            plural_examples: nil,
            model: nil
end
