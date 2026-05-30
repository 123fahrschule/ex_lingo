defmodule ExLingo.Storage.S3.Client do
  @moduledoc """
  Behaviour for performing S3 operations, so it can be mocked in tests.
  """

  @callback request(operation :: term(), config :: keyword()) ::
              {:ok, term()} | {:error, term()}
end

defmodule ExLingo.Storage.S3.ExAwsClient do
  @moduledoc false
  @behaviour ExLingo.Storage.S3.Client

  @impl true
  def request(operation, config), do: ExAws.request(operation, config)
end
