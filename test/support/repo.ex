defmodule ExLingo.Test.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :ex_lingo,
    adapter: Ecto.Adapters.Postgres
end
