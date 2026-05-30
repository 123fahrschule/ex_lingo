Application.ensure_all_started(:ex_lingo)

ExLingo.Test.Repo.start_link()
ExLingo.Test.Endpoint.start_link()

ExLingo.start_link(
  endpoint: ExLingo.Test.Endpoint,
  repo: ExLingo.Test.Repo,
  otp_name: :ex_lingo,
  plugins: []
)

Application.ensure_all_started(:mox)
Mox.defmock(ExLingo.Storage.S3.ClientMock, for: ExLingo.Storage.S3.Client)

ExUnit.start()

# clear translations cache
ExLingo.Cache.delete_all()

Ecto.Adapters.SQL.Sandbox.mode(ExLingo.Test.Repo, :manual)
