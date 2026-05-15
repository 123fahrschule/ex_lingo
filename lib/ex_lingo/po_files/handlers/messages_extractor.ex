defmodule ExLingo.PoFiles.MessagesExtractor do
  @moduledoc """
  Handler responsible for extracting data from .po files
  """

  @default_context "default"

  alias ExLingo.PoFiles.POFileParser
  alias ExLingo.PoFiles.Services.{ExtractPluralTranslation, ExtractSingularTranslation}

  def call do
    # Get config at top level
    otp_name = ExLingo.config().otp_name
    allowed_locales = Application.get_env(:ex_lingo, :allowed_locales)

    # The configured OTP application must be loaded so :code.priv_dir/1 can find priv/gettext.
    base_path = priv_gettext_path!(otp_name)

    # Pass explicitly to POFileParser
    result =
      POFileParser.parse_all_po_files(base_path, allowed_locales)
      |> Enum.flat_map(&extract_translations_from_parsed_file/1)

    {:ok, result}
  end

  defp extract_translations_from_parsed_file(%{
         locale: locale,
         domain: domain,
         messages: messages
       }) do
    plurals_header = get_plurals_header(messages, locale)

    messages
    |> Stream.map(fn
      %Expo.Message.Singular{
        msgctxt: nil,
        msgid: msgid,
        msgstr: texts,
        references: references
      } ->
        ExtractSingularTranslation.call(%{
          msgid: Enum.join(msgid),
          context_name: @default_context,
          locale_name: locale,
          domain_name: domain,
          original_text: Enum.join(texts),
          source_references: source_references(references)
        })

      %Expo.Message.Singular{
        msgctxt: [msgctxt],
        msgid: msgid,
        msgstr: texts,
        references: references
      } ->
        ExtractSingularTranslation.call(%{
          msgid: Enum.join(msgid),
          context_name: msgctxt,
          locale_name: locale,
          domain_name: domain,
          original_text: Enum.join(texts),
          source_references: source_references(references)
        })

      %Expo.Message.Plural{
        msgctxt: nil,
        msgid: msgid,
        msgstr: plurals_map,
        references: references
      } ->
        ExtractPluralTranslation.call(%{
          msgid: Enum.join(msgid),
          context_name: @default_context,
          locale_name: locale,
          domain_name: domain,
          plurals_map: plurals_map,
          plurals_header: plurals_header,
          source_references: source_references(references)
        })

      %Expo.Message.Plural{
        msgctxt: [msgctxt],
        msgid: msgid,
        msgstr: plurals_map,
        references: references
      } ->
        ExtractPluralTranslation.call(%{
          msgid: Enum.join(msgid),
          context_name: msgctxt,
          locale_name: locale,
          domain_name: domain,
          plurals_map: plurals_map,
          plurals_header: plurals_header,
          source_references: source_references(references)
        })
    end)
    |> Stream.filter(&(!is_nil(&1)))
  end

  defp get_plurals_header(messages, locale) do
    case Expo.PluralForms.plural_form(locale) do
      {:ok, plural_forms} ->
        Expo.PluralForms.to_string(plural_forms)

      :error ->
        Expo.Messages.get_header(messages, "Plural-Forms") |> List.first()
    end
  end

  defp source_references(references) when is_list(references) do
    references
    |> List.flatten()
    |> Enum.flat_map(fn
      {file, line} when is_binary(file) and is_integer(line) ->
        [%{"file" => file, "line" => line}]

      {file, line} when is_binary(file) ->
        [%{"file" => file, "line" => line}]

      _other ->
        []
    end)
    |> Enum.uniq()
  end

  defp source_references(_references), do: []

  defp priv_gettext_path!(otp_name) do
    case :code.priv_dir(otp_name) do
      {:error, reason} ->
        raise RuntimeError,
              "could not locate priv/gettext for #{inspect(otp_name)}: #{inspect(reason)}"

      path ->
        path
        |> to_string()
        |> Path.join("gettext")
    end
  rescue
    exception in ArgumentError ->
      raise RuntimeError,
            "could not locate priv/gettext for #{inspect(otp_name)}: #{Exception.message(exception)}"
  end
end
