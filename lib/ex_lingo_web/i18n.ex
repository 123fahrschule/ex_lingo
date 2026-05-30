defmodule ExLingoWeb.I18n do
  @moduledoc false

  import Phoenix.Component

  @supported_locales ~w(de en)
  @default_locale Application.compile_env(:ex_lingo, :default_locale, "en")
  @locale_key {__MODULE__, :locale}

  @de %{
    "Actions" => "Aktionen",
    "Accept" => "Übernehmen",
    "Adapt" => "Anpassen",
    "Adapted suggestion" => "Angepasster Vorschlag",
    "All" => "Alle",
    "All Stale" => "Alle veralteten",
    "Application" => "Anwendung",
    "Application scope" => "Anwendungs-Scope",
    "Application Source" => "Anwendung",
    "Application Sources" => "Anwendungen",
    "Applications" => "Anwendungen",
    "Are you sure you want to clear the translation cache?" =>
      "Möchtest du den Übersetzungscache wirklich leeren?",
    "Cache" => "Cache",
    "Changed from" => "geändert von",
    "Clear" => "Zurücksetzen",
    "Clear filters" => "Filter zurücksetzen",
    "Clear translation cache" => "Übersetzungscache leeren",
    "Color" => "Farbe",
    "Completion status by locale." => "Fortschritt pro Sprache.",
    "Compare the PO text with the editable ExLingo translation." =>
      "Vergleiche den PO-Text mit der bearbeitbaren ExLingo-Übersetzung.",
    "Create a locale before reviewing possible duplicates." =>
      "Lege eine Sprache an, bevor du mögliche Duplikate prüfst.",
    "Could not generate a suggestion: %{reason}" =>
      "Der Vorschlag konnte nicht erstellt werden: %{reason}",
    "Could not load application source." => "Die Anwendung konnte nicht geladen werden.",
    "Could not load domain." => "Die Domain konnte nicht geladen werden.",
    "Could not load glossary entry." => "Der Glossareintrag konnte nicht geladen werden.",
    "Could not update plural translation." =>
      "Die Plural-Übersetzung konnte nicht aktualisiert werden.",
    "Could not update translation." => "Die Übersetzung konnte nicht aktualisiert werden.",
    "Could not mark text as unclear." =>
      "Der Text konnte nicht als unverständlich markiert werden.",
    "Could not load translation." => "Die Übersetzung konnte nicht geladen werden.",
    "Context" => "Kontext",
    "Copied!" => "Kopiert!",
    "Copy AI instructions" => "KI-Anweisung kopieren",
    "Create application source" => "Anwendung anlegen",
    "Create glossary entry" => "Glossareintrag anlegen",
    "Dashboard" => "Dashboard",
    "Database identity, gettext scope, and source positions imported from PO files." =>
      "Datenbank-Identität, gettext-Scope und aus PO-Dateien importierte Quellpositionen.",
    "Define approved terminology for one language direction." =>
      "Definiere freigegebene Terminologie für eine Sprachrichtung.",
    "Define the source label and color used in translation lists." =>
      "Definiere Bezeichnung und Farbe der Quelle in Übersetzungslisten.",
    "Adjust the display color and optional description for this gettext domain." =>
      "Passe die Anzeigefarbe und optionale Beschreibung für diese gettext-Domain an.",
    "Delete" => "Löschen",
    "Delete all stale messages" => "Alle veralteten Texte löschen",
    "Delete all stale messages?" => "Alle veralteten Texte löschen?",
    "Delete glossary entry" => "Glossareintrag löschen",
    "Delete stale message" => "Veralteten Text löschen",
    "Delete stale message (all locales)" => "Veralteten Text löschen (alle Sprachen)",
    "Delete this glossary entry?" => "Diesen Glossareintrag löschen?",
    "Description" => "Beschreibung",
    "Direction" => "Richtung",
    "Domain" => "Domain",
    "Domain scope" => "Domain-Scope",
    "Domain settings" => "Domain-Einstellungen",
    "Domains" => "Domains",
    "Duplicate?" => "Duplikat?",
    "Edit" => "Bearbeiten",
    "Edit glossary entry" => "Glossareintrag bearbeiten",
    "ExLingo Dashboard" => "ExLingo Dashboard",
    "ExLingo Translation" => "ExLingo-Übersetzung",
    "ExLingo translated text" => "ExLingo-Übersetzungstext",
    "Effective translation" => "Wirksame Übersetzung",
    "Failed to delete glossary entry." => "Der Glossareintrag konnte nicht gelöscht werden.",
    "Failed to delete stale messages." => "Die veralteten Texte konnten nicht gelöscht werden.",
    "Failed to delete stale message." => "Der veraltete Text konnte nicht gelöscht werden.",
    "Failed to merge messages." => "Die Texte konnten nicht zusammengeführt werden.",
    "Form %{number}" => "Form %{number}",
    "Generating..." => "Wird erstellt...",
    "Generating suggestion..." => "Vorschlag wird erstellt...",
    "Global" => "Global",
    "Glossary" => "Glossar",
    "Glossary entries" => "Glossareinträge",
    "Glossary Entry" => "Glossareintrag",
    "ID" => "ID",
    "High confidence" => "Hohe Sicherheit",
    "Invalid AI provider: %{provider}." => "Ungültiger KI-Anbieter: %{provider}.",
    "Invalid AI suggestion form data." => "Ungültige Daten im KI-Vorschlagsformular.",
    "Invalid plural translation form data." => "Ungültige Daten im Plural-Übersetzungsformular.",
    "Items" => "Einträge",
    "Languages" => "Sprachen",
    "Locales" => "Sprachen",
    "Low confidence" => "Niedrige Sicherheit",
    "Merge" => "Zusammenführen",
    "Merge all mergeable messages" => "Alle zusammenführbaren Texte zusammenführen",
    "Merge all stale and mergeable messages?" =>
      "Alle veralteten und zusammenführbaren Texte zusammenführen?",
    "Merge message" => "Text zusammenführen",
    "Merge Message" => "Text zusammenführen",
    "Message Details" => "Textdetails",
    "Message ID" => "Text-ID",
    "Message" => "Text",
    "Messages" => "Texte",
    "Marked" => "Markiert",
    "Marked unclear" => "Als unverständlich markiert",
    "Medium confidence" => "Mittlere Sicherheit",
    "Model" => "Modell",
    "Mark this text as unclear for developers" =>
      "Diesen Text für Entwickler als unverständlich markieren",
    "Model %{model} is not allowed for this provider." =>
      "Das Modell %{model} ist für diesen Anbieter nicht erlaubt.",
    "MsgID" => "MsgID",
    "Name" => "Name",
    "New" => "Neu",
    "Next" => "Weiter",
    "Next page" => "Nächste Seite",
    "No glossary entries found." => "Keine Glossareinträge gefunden.",
    "No locales found." => "Keine Sprachen gefunden.",
    "No unclear texts." => "Keine unverständlichen Texte.",
    "No possible duplicates found." => "Keine möglichen Duplikate gefunden.",
    "No source positions were recorded in the imported PO files." =>
      "In den importierten PO-Dateien wurden keine Quellpositionen gespeichert.",
    "No repeated translation patterns were found for the selected locale." =>
      "Für die ausgewählte Sprache wurden keine wiederholten Übersetzungsmuster gefunden.",
    "No AI translation provider is configured." =>
      "Es ist kein KI-Übersetzungsanbieter konfiguriert.",
    "None" => "Keine",
    "Not translated" => "Nicht übersetzt",
    "Open unclear texts" => "Unverständliche Texte öffnen",
    "Pagination" => "Seitennavigation",
    "Page %{number}" => "Seite %{number}",
    "Plural form" => "Pluralform",
    "Plural Translation" => "Plural-Übersetzung",
    "PO Translation" => "PO-Übersetzung",
    "PO file text" => "PO-Dateitext",
    "Possible duplicate" => "Mögliches Duplikat",
    "Possible duplicates" => "Mögliche Duplikate",
    "Previous" => "Zurück",
    "Previous page" => "Vorherige Seite",
    "Probably:" => "Wahrscheinlich:",
    "Provider" => "Anbieter",
    "Plugins" => "Plugins",
    "Quantity examples: %{examples}" => "Mengenbeispiele: %{examples}",
    "Related messages" => "Verwandte Texte",
    "Review repeated translations that may be shared in application code." =>
      "Prüfe wiederholte Übersetzungen, die im Anwendungscode geteilt werden könnten.",
    "Runtime translation cache entries." => "Laufzeit-Übersetzungscache-Einträge.",
    "Save" => "Speichern",
    "Saving..." => "Speichern...",
    "Scope" => "Scope",
    "Search" => "Suche",
    "Singular Translation" => "Singular-Übersetzung",
    "Same source and translation" => "Gleicher Quelltext und gleiche Übersetzung",
    "Same translation" => "Gleiche Übersetzung",
    "Source Positions" => "Quellpositionen",
    "Source references" => "Quellpositionen",
    "Source strings" => "Quelltexte",
    "Source variant" => "Quelltext-Variante",
    "Source locale" => "Ausgangssprache",
    "Source term" => "Ausgangsbegriff",
    "Stale" => "Veraltet",
    "Stale & Mergeable" => "Veraltet & zusammenführbar",
    "Suggest" => "Vorschlagen",
    "Suggestion" => "Vorschlag",
    "Target locale" => "Zielsprache",
    "Target term" => "Zielbegriff",
    "Text marked as unclear." => "Der Text wurde als unverständlich markiert.",
    "Texts marked by translators because the gettext context is not clear enough." =>
      "Texte, die Übersetzer markiert haben, weil der gettext-Kontext nicht verständlich genug ist.",
    "The AI provider API key is missing." => "Der API-Key des KI-Anbieters fehlt.",
    "The name comes from gettext and is used to scope imported messages." =>
      "Der Name kommt aus gettext und wird zum Scoping importierter Texte verwendet.",
    "This will:" => "Das passiert:",
    "Move all translations from '%{from}' to '%{to}'" =>
      "Alle Übersetzungen werden von '%{from}' nach '%{to}' verschoben",
    "Overwrite existing translations in '%{target}' (unless missing in source)" =>
      "Bestehende Übersetzungen in '%{target}' werden überschrieben (außer sie fehlen in der Quelle)",
    "Delete '%{message}' from all locales" => "'%{message}' wird aus allen Sprachen gelöscht",
    "This action is irreversible. Are you sure?" =>
      "Diese Aktion kann nicht rückgängig gemacht werden. Bist du sicher?",
    "Delete Stale Message" => "Veralteten Text löschen",
    "This will permanently delete this message and its translations across ALL locales." =>
      "Dadurch wird dieser Text mit allen Übersetzungen in allen Sprachen dauerhaft gelöscht.",
    "This action is irreversible." => "Diese Aktion kann nicht rückgängig gemacht werden.",
    "This translation may be shared with other active messages." =>
      "Diese Übersetzung wird möglicherweise mit anderen aktiven Texten geteilt.",
    "This message can be merged with a similar message that exists in PO files" =>
      "Dieser Text kann mit einem ähnlichen Text aus den PO-Dateien zusammengeführt werden",
    "This message exists in the database but is no longer present in any locale's PO files" =>
      "Dieser Text existiert in der Datenbank, ist aber in keiner PO-Datei mehr vorhanden",
    "This will move translations from stale messages to their best matching messages, overwrite target translations where applicable, and delete stale message IDs from all locales." =>
      "Dadurch werden Übersetzungen von veralteten Texten zu den besten passenden Texten verschoben, Zielübersetzungen bei Bedarf überschrieben und veraltete Text-IDs aus allen Sprachen gelöscht.",
    "This will permanently delete all stale messages and their translations across all locales." =>
      "Dadurch werden alle veralteten Texte und ihre Übersetzungen in allen Sprachen dauerhaft gelöscht.",
    "Toggle dark mode" => "Dark Mode umschalten",
    "Translate to %{locale}" => "Nach %{locale} übersetzen",
    "Translation ID" => "Übersetzungs-ID",
    "Translation Progress" => "Übersetzungsfortschritt",
    "Translation" => "Übersetzung",
    "Type" => "Typ",
    "Unclear text" => "Unverständlich",
    "Unclear texts" => "Unverständliche Texte",
    "%{count} possible duplicate groups" => "%{count} mögliche Duplikatgruppen",
    "Update application source" => "Anwendung aktualisieren",
    "Update glossary entry" => "Glossareintrag aktualisieren",
    "Usage guidance" => "Hinweise zur Verwendung",
    "When translators mark a text as unclear, it will appear here with source positions." =>
      "Wenn Übersetzer einen Text als unverständlich markieren, erscheint er hier mit Quellpositionen.",
    "Used for badges and filters in translation tables." =>
      "Wird für Badges und Filter in Übersetzungstabellen verwendet.",
    "Workspace" => "Arbeitsbereich",
    "Settings" => "Einstellungen",
    "AI translation prompt" => "KI-Übersetzungs-Prompt",
    "AI translation prompts saved." => "KI-Übersetzungs-Prompt gespeichert.",
    "This template is the complete text sent to the AI for each suggestion. Edit it freely and use the placeholders below." =>
      "Diese Vorlage ist der vollständige Text, der bei jedem Vorschlag an die KI gesendet wird. Bearbeite sie frei und nutze die Platzhalter unten.",
    "Global prompt template" => "Globale Prompt-Vorlage",
    "Used for all locales unless overridden below." =>
      "Wird für alle Sprachen verwendet, sofern unten nicht überschrieben.",
    "Per-locale overrides" => "Sprachspezifische Überschreibungen",
    "Empty = use global template" => "Leer = globale Vorlage verwenden",
    "Save AI prompt" => "KI-Prompt speichern",
    "Available placeholders" => "Verfügbare Platzhalter",
    "Insert these tokens anywhere in the template; they are replaced per request. Required placeholders are always sent to the AI even if you remove them from the template." =>
      "Füge diese Tokens an beliebiger Stelle in die Vorlage ein; sie werden pro Anfrage ersetzt. Pflicht-Platzhalter werden immer an die KI gesendet, auch wenn du sie aus der Vorlage entfernst.",
    "Required — always sent" => "Pflichtfeld – wird immer gesendet",
    "Optional" => "Optional",
    "* required — at minimum the AI always receives the source text and the target locale." =>
      "* Pflichtfeld – die KI erhält mindestens den Quelltext und die Ziel-Sprache.",
    "S3 storage" => "S3-Speicher",
    "Credentials for image uploads used as translation context." =>
      "Zugangsdaten für Bild-Uploads, die als Übersetzungskontext dienen.",
    "Access key ID" => "Zugriffsschlüssel-ID",
    "Secret access key" => "Geheimer Zugriffsschlüssel",
    "Bucket" => "Bucket",
    "Region" => "Region",
    "Folder prefix" => "Ordner-Präfix",
    "Not set" => "Nicht gesetzt",
    "Stored — leave blank to keep" => "Gespeichert – leer lassen, um beizubehalten",
    "Subfolder inside the bucket where screenshots are stored, e.g. ex_lingo/. Defaults to the bucket root (/) — useful when one bucket is shared across services." =>
      "Unterordner im Bucket, in dem Screenshots gespeichert werden, z. B. ex_lingo/. Standard ist das Bucket-Stammverzeichnis (/) – nützlich, wenn ein Bucket von mehreren Diensten gemeinsam genutzt wird.",
    "Test connection" => "Verbindung testen",
    "S3 connection testing becomes available with image uploads (briefing 07)." =>
      "Der S3-Verbindungstest wird mit den Bild-Uploads verfügbar (Briefing 07).",
    "S3 storage settings saved." => "S3-Speichereinstellungen gespeichert.",
    "Save S3 settings" => "S3-Einstellungen speichern",
    "Translation quality warnings" => "Übersetzungsqualitäts-Warnungen",
    "Thresholds for the advisory length warnings shown while translating. Tighten them for mobile UIs, relax them for web. Leave a field empty to use the default." =>
      "Schwellwerte für die beratenden Längenwarnungen während des Übersetzens. Strenger für mobile Oberflächen, lockerer fürs Web. Leeres Feld = Standardwert.",
    "Length warning ratio" => "Längen-Warnverhältnis",
    "Translation longer than this multiple of the source shows a warning." =>
      "Eine Übersetzung, die länger als dieses Vielfache des Quelltexts ist, zeigt eine Warnung.",
    "Length error ratio" => "Längen-Fehlerverhältnis",
    "Translation longer than this multiple flags a hard length problem." =>
      "Eine Übersetzung, die länger als dieses Vielfache ist, meldet ein hartes Längenproblem.",
    "Short string threshold" => "Kurztext-Schwelle",
    "Sources shorter than this many characters use absolute character limits instead of ratios." =>
      "Quelltexte, die kürzer als diese Zeichenanzahl sind, verwenden absolute Zeichengrenzen statt Verhältnisse.",
    "Short string warning (characters)" => "Kurztext-Warnung (Zeichen)",
    "Extra characters over a short source before a warning shows." =>
      "Zusätzliche Zeichen gegenüber einem kurzen Quelltext, ab denen eine Warnung erscheint.",
    "Short string error (characters)" => "Kurztext-Fehler (Zeichen)",
    "Extra characters over a short source before a hard length problem flags." =>
      "Zusätzliche Zeichen gegenüber einem kurzen Quelltext, ab denen ein hartes Längenproblem gemeldet wird.",
    "Save quality thresholds" => "Qualitäts-Schwellwerte speichern",
    "Translation quality thresholds saved." => "Qualitäts-Schwellwerte gespeichert."
  }

  def on_mount(_arg, params, session, socket) do
    locale =
      params
      |> get_locale()
      |> Kernel.||(get_locale(session))
      |> Kernel.||(Map.get(session, "ex_lingo_locale"))
      |> put_locale()

    {:cont, assign(socket, :ex_lingo_locale, locale)}
  end

  def current_ui_locale(%Plug.Conn{} = conn) do
    conn
    |> locale_from_conn()
    |> put_locale()
  end

  def current_ui_locale(%Phoenix.LiveView.Socket{} = socket) do
    socket.assigns
    |> Map.get(:ex_lingo_locale)
    |> put_locale()
  end

  def current_ui_locale(%{} = assigns) do
    assigns
    |> Map.get(:ex_lingo_locale)
    |> put_locale()
  end

  def current_ui_locale(_), do: put_locale(current_locale())

  def locale_from_socket(%Phoenix.LiveView.Socket{assigns: %{ex_lingo_locale: locale}}) do
    locale
  end

  def locale_from_socket(%Phoenix.LiveView.Socket{}), do: current_locale()

  def locale_from_conn(conn) do
    get_locale(conn.params) ||
      get_locale(conn.assigns) ||
      session_locale(conn) ||
      get_locale(conn.cookies) ||
      @default_locale
  end

  def put_locale(locale) do
    locale = normalize_locale(locale)

    Gettext.put_locale(locale)
    Process.put(@locale_key, locale)

    locale
  end

  def current_locale do
    Process.get(@locale_key) || normalize_locale(Gettext.get_locale())
  end

  def t(message, bindings \\ []) when is_binary(message) do
    message
    |> translate(current_locale())
    |> interpolate(bindings)
  end

  def append_locale(path, locale \\ current_locale()) when is_binary(path) do
    uri = URI.parse(path)

    query =
      uri.query
      |> decode_query()
      |> Map.put("locale", normalize_locale(locale))

    uri
    |> Map.put(:query, URI.encode_query(query))
    |> URI.to_string()
  end

  defp translate(message, "de"), do: Map.get(@de, message, message)
  defp translate(message, _locale), do: message

  defp interpolate(message, bindings) do
    Enum.reduce(bindings, message, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp normalize_locale(locale) when is_atom(locale),
    do: locale |> Atom.to_string() |> normalize_locale()

  defp normalize_locale(locale) when is_binary(locale) do
    locale =
      locale
      |> String.downcase()
      |> String.replace("_", "-")
      |> String.split("-")
      |> List.first()

    if locale in @supported_locales, do: locale, else: normalize_locale(@default_locale)
  end

  defp normalize_locale(_), do: normalize_locale(@default_locale)

  defp get_locale(%{} = params) do
    params[:locale] || params["locale"] || params[:ui_locale] || params["ui_locale"]
  end

  defp get_locale(_), do: nil

  defp session_locale(conn) do
    Plug.Conn.get_session(conn, :locale) ||
      Plug.Conn.get_session(conn, "locale")
  rescue
    ArgumentError -> nil
  end

  defp decode_query(nil), do: %{}
  defp decode_query(""), do: %{}
  defp decode_query(query), do: URI.decode_query(query)
end
