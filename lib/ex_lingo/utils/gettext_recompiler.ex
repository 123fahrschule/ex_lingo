defmodule ExLingo.Utils.GettextRecompiler do
  @moduledoc """
  Handles recompilation detection for Gettext backends during extraction.

  This module manages flag files that track when Gettext extraction occurs,
  allowing the system to trigger recompilation when needed.
  """

  def flag_file(filename) do
    Path.join([build_path(), "ex_lingo_recompile", filename])
  end

  def setup_recompile_flag(flag_file) do
    if Gettext.Extractor.extracting?() do
      File.mkdir_p!(Path.dirname(flag_file))
      File.touch!(flag_file)
    end
  end

  def needs_recompile?(flag_file) do
    if !Gettext.Extractor.extracting?() && File.exists?(flag_file) do
      File.rm!(flag_file)
      true
    else
      false
    end
  end

  defp build_path do
    Mix.Project.build_path()
  rescue
    Mix.NoProjectError -> System.tmp_dir!()
  end
end
