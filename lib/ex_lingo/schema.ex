defmodule ExLingo.Schema do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      @primary_key {:id, Application.compile_env(:ex_lingo, :schema_id_type, :id),
                    autogenerate: true}
      @foreign_key_type Application.compile_env(:ex_lingo, :schema_id_type, :id)
    end
  end
end
