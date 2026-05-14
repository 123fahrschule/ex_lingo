defmodule ExLingo.Specs.SchemataSpec do
  @moduledoc false

  @type schema() :: {String.t(), %{schema: atom(), conflict_target: atom() | [atom()]}}

  @type t() :: [schema()]
end
