defmodule ExLingo.Storage.S3Test do
  use ExLingo.Test.DataCase, async: false

  import Mox

  alias ExLingo.Settings
  alias ExLingo.Storage.S3
  alias ExLingo.Storage.S3.ClientMock

  setup :verify_on_exit!

  setup do
    ExLingo.Cache.delete_all()

    previous = Application.get_env(:ex_lingo, :s3_client)
    Application.put_env(:ex_lingo, :s3_client, ClientMock)

    on_exit(fn ->
      if previous do
        Application.put_env(:ex_lingo, :s3_client, previous)
      else
        Application.delete_env(:ex_lingo, :s3_client)
      end
    end)

    :ok
  end

  defp configure_s3(attrs \\ %{}) do
    {:ok, _} =
      Settings.update(
        Map.merge(
          %{
            "s3_access_key_id" => "AKIATEST",
            "s3_secret_access_key" => "secret",
            "s3_bucket" => "my-bucket",
            "s3_region" => "eu-central-1"
          },
          attrs
        )
      )
  end

  describe "object_key/2" do
    test "places the key under the configured folder prefix" do
      configure_s3(%{"s3_prefix" => "ex_lingo/"})

      key = S3.object_key(42, "Screenshot.PNG")

      assert String.starts_with?(key, "ex_lingo/messages/42/")
      assert String.ends_with?(key, ".png")
    end

    test "uses the bucket root when prefix is /" do
      configure_s3(%{"s3_prefix" => "/"})

      key = S3.object_key(42, "shot.jpg")

      assert String.starts_with?(key, "messages/42/")
      refute String.starts_with?(key, "/")
    end
  end

  describe "put/3 and delete/1" do
    test "issues a put_object request" do
      configure_s3()

      expect(ClientMock, :request, fn operation, config ->
        assert operation.http_method == :put
        assert operation.bucket == "my-bucket"
        assert config[:access_key_id] == "AKIATEST"
        {:ok, %{status_code: 200}}
      end)

      assert {:ok, %{status_code: 200}} = S3.put("messages/1/a.png", "binary", "image/png")
    end

    test "issues a delete_object request" do
      configure_s3()

      expect(ClientMock, :request, fn operation, _config ->
        assert operation.http_method == :delete
        {:ok, %{status_code: 204}}
      end)

      assert {:ok, _} = S3.delete("messages/1/a.png")
    end
  end

  describe "test_connection/0" do
    test "returns :ok when the bucket responds" do
      configure_s3()

      expect(ClientMock, :request, fn _operation, _config -> {:ok, %{status_code: 200}} end)

      assert S3.test_connection() == :ok
    end

    test "passes through an error reason" do
      configure_s3()

      expect(ClientMock, :request, fn _operation, _config -> {:error, "403 Forbidden"} end)

      assert S3.test_connection() == {:error, "403 Forbidden"}
    end

    test "returns :not_configured when credentials are missing" do
      _seed = Settings.get()

      assert S3.test_connection() == {:error, :not_configured}
    end
  end

  describe "presigned_url/2" do
    test "builds a signed GET url for the object" do
      configure_s3(%{"s3_prefix" => "/"})

      assert {:ok, url} = S3.presigned_url("messages/1/a.png")
      assert url =~ "my-bucket"
      assert url =~ "messages/1/a.png"
      assert url =~ "X-Amz-Signature"
    end
  end
end
