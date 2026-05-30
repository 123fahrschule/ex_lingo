defmodule ExLingo.Translations.ValidationsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExLingo.Translations.Validations

  describe "length_status/2" do
    test "equal length is ok" do
      assert Validations.length_status("Hello world", "Hallo Welt!") == :ok
    end

    test "empty target is always ok" do
      assert Validations.length_status("Hello", "") == :ok
    end

    test "long original — slightly_long once target exceeds 1.3x" do
      source = String.duplicate("a", 20)
      target = String.duplicate("a", 30)
      assert Validations.length_status(source, target) == :slightly_long
    end

    test "long original — too_long once target exceeds 1.8x" do
      source = String.duplicate("a", 20)
      target = String.duplicate("a", 40)
      assert Validations.length_status(source, target) == :too_long
    end

    test "short original uses absolute diff thresholds" do
      assert Validations.length_status("OK", "OK") == :ok
      assert Validations.length_status("OK", "OK?!") == :ok
      assert Validations.length_status("OK", "Einverstanden") == :slightly_long
      assert Validations.length_status("OK", String.duplicate("x", 20)) == :too_long
    end

    test "empty source falls back to absolute diff" do
      assert Validations.length_status("", "") == :ok
      assert Validations.length_status("", "short") == :ok
      assert Validations.length_status("", String.duplicate("x", 20)) == :too_long
    end
  end

  describe "missing_placeholders/2" do
    test "no placeholders in either string" do
      assert Validations.missing_placeholders("Hello", "Hallo") == []
    end

    test "all placeholders preserved" do
      assert Validations.missing_placeholders(
               "Hello %{name}, you have %{count} messages",
               "Ciao %{name}, hai %{count} messaggi"
             ) == []
    end

    test "lists missing placeholders" do
      assert Validations.missing_placeholders("Hello %{name}", "Hallo") == ["%{name}"]
    end

    test "lists multiple missing placeholders in source order, deduplicated" do
      result =
        Validations.missing_placeholders(
          "Hi %{user}, %{user} sent %{count} messages",
          "Salut"
        )

      assert result == ["%{user}", "%{count}"]
    end

    test "ignores extra placeholders in target" do
      assert Validations.missing_placeholders("Hi", "Hi %{stranger}") == []
    end
  end

  describe "sentence_ending_mismatch?/2" do
    test "matching period" do
      refute Validations.sentence_ending_mismatch?("Hello.", "Hallo.")
    end

    test "missing period in target" do
      assert Validations.sentence_ending_mismatch?("Hello.", "Hallo")
    end

    test "different terminator counts as mismatch" do
      assert Validations.sentence_ending_mismatch?("Hello!", "Hallo.")
    end

    test "question mark mismatch" do
      assert Validations.sentence_ending_mismatch?("Continue?", "Weiter")
      refute Validations.sentence_ending_mismatch?("Continue?", "Weiter?")
    end

    test "colon and semicolon also tracked" do
      assert Validations.sentence_ending_mismatch?("Name:", "Name")
      assert Validations.sentence_ending_mismatch?("a; b; c;", "a, b, c")
    end

    test "target adds sentence-ending the source lacks — mismatch" do
      assert Validations.sentence_ending_mismatch?("Save", "Speichern.")
      assert Validations.sentence_ending_mismatch?("Save", "Weiter!")
      assert Validations.sentence_ending_mismatch?("Name", "Name:")
    end

    test "neither source nor target has a sentence-ending — no mismatch" do
      refute Validations.sentence_ending_mismatch?("Save", "Speichern")
    end

    test "empty target — no mismatch reported" do
      refute Validations.sentence_ending_mismatch?("Hello.", "")
    end

    test "trailing whitespace is ignored" do
      refute Validations.sentence_ending_mismatch?("Hello.", "Hallo.   ")
    end
  end
end
