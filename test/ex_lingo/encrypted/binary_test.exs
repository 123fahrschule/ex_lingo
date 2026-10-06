defmodule ExLingo.Encrypted.BinaryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias ExLingo.Encrypted.Binary
  alias ExLingo.Encrypted.Cipher

  @header <<1, 10, "AES.GCM.V1">>

  # Produced by the real Cloak library (Cloak.Ciphers.AES.GCM.encrypt/2 with
  # tag "AES.GCM.V1", iv_length 12, key = SHA-256 of the secret) before Cloak
  # was removed.
  @legacy_secret "legacy-test-secret"
  @legacy_plaintext "known-answer-value"
  @legacy_value Base.decode64!(
                  "AQpBRVMuR0NNLlYxeOOY2kPyGrVnExLLCM8Kj5WMbHtpzZpjjQv1Mtd9pnx17ArH0gOatoVFXbxpqQ=="
                )

  setup do
    previous = Application.fetch_env(:ex_lingo, :settings_encryption_key)
    Application.put_env(:ex_lingo, :settings_encryption_key, "test-secret-one")

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:ex_lingo, :settings_encryption_key, value)
        :error -> Application.delete_env(:ex_lingo, :settings_encryption_key)
      end
    end)
  end

  defp encrypt!(value) do
    {:ok, dumped} = Binary.dump(value)
    dumped
  end

  describe "round trip" do
    for value <- [
          "",
          "secret",
          "ünïcödé — 日本語 🔐",
          <<0, 255, 1, 2>>,
          String.duplicate("x", 10_000)
        ] do
      test "restores #{inspect(String.slice(value, 0, 12))} (#{byte_size(value)} bytes)" do
        assert {:ok, unquote(value)} = Binary.load(encrypt!(unquote(value)))
      end
    end

    test "nil stays nil" do
      assert Binary.dump(nil) == {:ok, nil}
      assert Binary.load(nil) == {:ok, nil}
      assert Binary.cast(nil) == {:ok, nil}
    end

    test "uses the documented layout" do
      <<@header, _iv::binary-size(12), _tag::binary-size(16), ciphertext::binary>> =
        encrypt!("abc")

      assert byte_size(ciphertext) == 3
    end

    test "encrypting the same value twice gives different results" do
      refute encrypt!("same") == encrypt!("same")
    end

    test "the plaintext does not appear in the stored value" do
      refute encrypt!("plain-visible-text") =~ "plain-visible-text"
    end
  end

  # Cipher.decrypt/2 is the strict layer: anything unreadable is :error.
  # Binary.load/1 degrades that to nil (plus a warning) so a bad secret
  # cannot break reading a whole row.
  defp rejected?(stored) do
    secret = Application.get_env(:ex_lingo, :settings_encryption_key)
    Cipher.decrypt(stored, secret) == :error and silent_nil?(stored)
  end

  defp silent_nil?(stored) do
    {result, log} = with_log(fn -> Binary.load(stored) end)
    result == {:ok, nil} and log =~ "could not be decrypted"
  end

  describe "tampering" do
    test "a changed byte at every position is rejected" do
      stored = encrypt!("tamper-me")

      for pos <- 0..(byte_size(stored) - 1) do
        <<head::binary-size(pos), byte, tail::binary>> = stored
        damaged = <<head::binary, Bitwise.bxor(byte, 0x01), tail::binary>>
        assert rejected?(damaged), "byte #{pos} was not detected"
      end
    end

    test "truncated values are rejected" do
      stored = encrypt!("truncate-me")

      for len <- 0..(byte_size(stored) - 1) do
        assert rejected?(binary_part(stored, 0, len)), "length #{len} accepted"
      end
    end

    test "extended values are rejected" do
      stored = encrypt!("extend-me")

      assert rejected?(stored <> <<0>>)
      assert rejected?(stored <> "tail")
    end

    test "non-binary and foreign values are rejected" do
      for value <- [123, :atom, 1.5, %{}, [1, 2], {:ok, "x"}, "plain text", "", <<1, 10>>] do
        assert rejected?(value)
      end
    end

    test "load/1 never yields {:ok, :error} and never logs the key, plaintext or ciphertext" do
      stored = encrypt!("x-plain-marker")
      <<head::binary-size(byte_size(stored) - 1), last>> = stored
      damaged = <<head::binary, Bitwise.bxor(last, 1)>>

      log = capture_log(fn -> assert Binary.load(damaged) == {:ok, nil} end)

      refute log =~ "x-plain-marker"
      refute log =~ "test-secret-one"
      refute log =~ Base.encode64(damaged)
      refute log =~ inspect(damaged)
    end
  end

  describe "keys" do
    test "another key does not decrypt" do
      stored = encrypt!("key-bound")
      Application.put_env(:ex_lingo, :settings_encryption_key, "test-secret-two")

      assert rejected?(stored)
    end

    test "the key is read from the environment on every call" do
      Application.put_env(:ex_lingo, :settings_encryption_key, "rotating-a")
      a = encrypt!("v")
      Application.put_env(:ex_lingo, :settings_encryption_key, "rotating-b")
      b = encrypt!("v")

      assert Binary.load(b) == {:ok, "v"}
      assert silent_nil?(a)
    end

    test "falls back to a built-in secret when none is configured" do
      Application.delete_env(:ex_lingo, :settings_encryption_key)

      assert {:ok, "fallback"} = Binary.load(encrypt!("fallback"))
    end
  end

  describe "known answer" do
    test "a value produced by Cloak still decrypts" do
      assert Cipher.decrypt(@legacy_value, @legacy_secret) == {:ok, @legacy_plaintext}

      Application.put_env(:ex_lingo, :settings_encryption_key, @legacy_secret)
      assert Binary.load(@legacy_value) == {:ok, @legacy_plaintext}
    end

    test "the legacy value is rejected with a different key" do
      assert rejected?(@legacy_value)
    end

    test "our output decrypts with :crypto used directly (independent of Cipher)" do
      stored = Cipher.encrypt(@legacy_plaintext, @legacy_secret)
      key = :crypto.hash(:sha256, @legacy_secret)

      <<1, 10, "AES.GCM.V1", iv::binary-size(12), tag::binary-size(16), ct::binary>> = stored

      assert :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ct, "AES256GCM", tag, false) ==
               @legacy_plaintext
    end

    test "our output uses the same layout as the legacy value" do
      <<@header, _::binary-size(12), _::binary-size(16), rest::binary>> =
        Cipher.encrypt(@legacy_plaintext, @legacy_secret)

      assert byte_size(rest) == byte_size(@legacy_plaintext)

      assert byte_size(@legacy_value) ==
               byte_size(Cipher.encrypt(@legacy_plaintext, @legacy_secret))
    end
  end

  describe "ecto callbacks" do
    test "cast accepts binaries only" do
      assert Binary.cast("abc") == {:ok, "abc"}
      assert Binary.cast(123) == :error
    end

    test "dump rejects non-binaries without leaking the value" do
      assert Binary.dump(123) == :error
    end

    test "type and embed_as" do
      assert Binary.type() == :binary
      assert Binary.embed_as(:json) == :self
      assert Binary.equal?("a", "a")
    end
  end
end
