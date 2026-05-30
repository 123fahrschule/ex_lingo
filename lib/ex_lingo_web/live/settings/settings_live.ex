defmodule ExLingoWeb.Settings.SettingsLive do
  use ExLingoWeb, :live_view

  alias ExLingo.AI.Translations.PromptRenderer
  alias ExLingo.Settings
  alias ExLingo.Settings.Setting
  alias ExLingo.Storage.S3
  alias ExLingo.Translations

  def mount(_params, _session, socket) do
    {:ok, assign_settings(socket, Settings.get())}
  end

  def handle_event("save_ai", %{"ai" => attrs}, socket) do
    case Settings.update(take_ai(attrs)) do
      {:ok, setting} ->
        {:noreply,
         socket
         |> assign_settings(setting)
         |> put_flash(:info, t("AI translation prompts saved."))}

      {:error, changeset} ->
        {:noreply, assign(socket, :ai_form, to_form(changeset, as: :ai))}
    end
  end

  def handle_event("save_s3", %{"s3" => attrs}, socket) do
    case Settings.update(take_s3(attrs)) do
      {:ok, setting} ->
        {:noreply,
         socket
         |> assign_settings(setting)
         |> put_flash(:info, t("S3 storage settings saved."))}

      {:error, changeset} ->
        {:noreply, assign(socket, :s3_form, to_form(changeset, as: :s3))}
    end
  end

  def handle_event("test_s3", _params, socket) do
    socket =
      case S3.test_connection() do
        :ok ->
          put_flash(socket, :info, t("S3 connection succeeded."))

        {:error, :not_configured} ->
          put_flash(socket, :error, t("Enter and save the S3 credentials before testing."))

        {:error, reason} ->
          put_flash(socket, :error, t("S3 connection failed: %{reason}", reason: inspect(reason)))
      end

    {:noreply, socket}
  end

  def handle_event("save_validations", %{"validations" => attrs}, socket) do
    case Settings.update(take_validations(attrs)) do
      {:ok, setting} ->
        {:noreply,
         socket
         |> assign_settings(setting)
         |> put_flash(:info, t("Translation quality thresholds saved."))}

      {:error, changeset} ->
        {:noreply, assign(socket, :validations_form, to_form(changeset, as: :validations))}
    end
  end

  @doc "Per-locale prompt template currently stored for a locale code (empty when unset)."
  def locale_prompt(setting, locale_code) do
    setting.ai_prompt_template_per_locale
    |> Kernel.||(%{})
    |> Map.get(locale_code, "")
  end

  @doc """
  Reference box listing every placeholder usable in the prompt template and
  which ones are always sent to the AI (the mandatory minimum).
  """
  def placeholder_box(assigns) do
    required = PromptRenderer.required_placeholders()
    assigns = assign(assigns, :placeholders, PromptRenderer.placeholders())
    assigns = assign(assigns, :required, required)

    ~H"""
    <.alert variant="default" class="mb-6">
      <.icon name="info" size="sm" decorative />
      <.alert_title>{t("Available placeholders")}</.alert_title>
      <.alert_description>
        <p class="mb-2">
          {t("Insert these tokens anywhere in the template; they are replaced per request. Required placeholders are always sent to the AI even if you remove them from the template.")}
        </p>
        <div class="flex flex-wrap gap-1.5">
          <code
            :for={name <- @placeholders}
            class="rounded bg-muted px-1.5 py-0.5 text-body-sm"
            title={if name in @required, do: t("Required — always sent"), else: t("Optional")}
          >
            {"{{#{name}}}"}{if name in @required, do: " *", else: ""}
          </code>
        </div>
        <p class="mt-2 text-body-sm text-muted-foreground">
          {t("* required — at minimum the AI always receives the source text and the target locale.")}
        </p>
      </.alert_description>
    </.alert>
    """
  end

  @doc "Default validation thresholds, used as input placeholders."
  def validation_defaults, do: Settings.validation_defaults()

  defp assign_settings(socket, %Setting{} = setting) do
    socket
    |> assign(:setting, setting)
    |> assign(:locales, list_locales())
    |> assign(:ai_form, to_form(Settings.change(setting), as: :ai))
    |> assign(:s3_form, to_form(Settings.change(setting), as: :s3))
    |> assign(:validations_form, to_form(Settings.change(setting), as: :validations))
    |> assign(:s3_secret_present?, Setting.s3_secret_present?(setting))
  end

  defp list_locales do
    %{entries: locales} = Translations.list_locales()
    locales
  end

  defp take_ai(attrs) do
    Map.take(attrs, ["ai_prompt_template", "ai_prompt_template_per_locale"])
  end

  defp take_s3(attrs) do
    Map.take(attrs, [
      "s3_access_key_id",
      "s3_secret_access_key",
      "s3_bucket",
      "s3_region",
      "s3_prefix"
    ])
  end

  defp take_validations(attrs) do
    Map.take(attrs, [
      "validation_length_warning_ratio",
      "validation_length_error_ratio",
      "validation_short_string_threshold",
      "validation_short_abs_warning",
      "validation_short_abs_error"
    ])
  end
end
