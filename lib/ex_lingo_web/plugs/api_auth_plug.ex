defmodule ExLingoWeb.APIAuthPlug do
  @moduledoc false

  import Plug.Conn
  require Logger

  @ex_lingo_secret_token "EX_LINGO_SECRET_TOKEN"

  def warn_if_secret_missing(%{disable_api_authorization: false}) do
    if is_nil(System.get_env(@ex_lingo_secret_token)) do
      Logger.warning(
        "[ExLingo] API authorization is enabled, but #{@ex_lingo_secret_token} is not set."
      )
    end
  end

  def warn_if_secret_missing(_config), do: :ok

  def init(_opts), do: %{}

  def call(conn, _opts) do
    if api_authorization_disabled?() or bearer_token_valid?(conn) do
      conn
    else
      conn
      |> send_resp(
        401,
        "Incorrect authorization Bearer token."
      )
      |> halt()
    end
  end

  defp bearer_token_valid?(conn) do
    with {:ok, token} <- extract_bearer_token(conn),
         true <- secret_token_matching?(token) do
      true
    else
      _ -> false
    end
  end

  defp secret_token_matching?(token) do
    secret_token_env = System.get_env(@ex_lingo_secret_token)

    with true <- is_binary(secret_token_env),
         true <- is_binary(token),
         expected <- sha256(secret_token_env),
         true <- byte_size(expected) == byte_size(token) do
      Plug.Crypto.secure_compare(expected, token)
    else
      _ -> false
    end
  end

  defp extract_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        {:ok, token}

      _ ->
        :error
    end
  end

  defp sha256(token) do
    :crypto.hash(:sha256, token)
    |> Base.encode64()
  end

  defp api_authorization_disabled? do
    ExLingo.config().disable_api_authorization
  end
end
