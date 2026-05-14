defmodule ExLingo.Registry do
  @moduledoc """
  ExLingo Registry
  """

  def child_spec(_arg) do
    [keys: :unique, name: __MODULE__]
    |> Registry.child_spec()
    |> Supervisor.child_spec(id: __MODULE__)
  end

  @doc """
  Fetch the config for an ExLingo supervisor instance.

  ## Example

  Get the default instance config:

      ExLingo.Registry.config(ExLingo)

  Get config for a custom named instance:

      ExLingo.Registry.config(MyApp.ExLingo)
  """
  @spec config(atom()) :: ExLingo.Config.t()
  def config(ex_lingo_name) do
    case lookup(ex_lingo_name) do
      {_pid, config} ->
        config

      _ ->
        raise RuntimeError, """
        No ExLingo instance named `#{inspect(ex_lingo_name)}` is running and config isn't available.
        """
    end
  end

  @doc """
  Find the `{pid, value}` pair for a registered ExLingo process.

  ## Example

  Get the default instance config:

      ExLingo.Registry.lookup(ExLingo)

  Get a supervised module's pid:

      ExLingo.Registry.lookup(ExLingo, ExLingo.Notifier)
  """
  def lookup(ex_lingo_name, role \\ nil) do
    __MODULE__
    |> Registry.lookup(key(ex_lingo_name, role))
    |> List.first()
  end

  @doc """
  Returns the pid of a supervised ExLingo process, or `nil` if the process can't be found.

  ## Example

  Get the ExLingo supervisor's pid:

      ExLingo.Registry.whereis(ExLingo)

  Get the pid for a plugin:

      ExLingo.Registry.whereis(ExLingo, {:plugin, MyApp.ExLingo.Plugin})
  """
  def whereis(ex_lingo_name, role \\ nil) do
    ex_lingo_name
    |> via(role)
    |> GenServer.whereis()
  end

  @doc """
  Build a via tuple suitable for calls to a supervised ExLingo process.

  ## Example

  For an ExLingo supervisor:

      ExLingo.Registry.via(ExLingo)

  For a plugin:

      ExLingo.Registry.via(ExLingo, {:plugin, ExLingo.DeepL.Plugin})
  """
  def via(ex_lingo_name, role \\ nil, value \\ nil)
  def via(ex_lingo_name, role, nil), do: {:via, Registry, {__MODULE__, key(ex_lingo_name, role)}}

  def via(ex_lingo_name, role, value),
    do: {:via, Registry, {__MODULE__, key(ex_lingo_name, role), value}}

  defp key(ex_lingo_name, nil), do: ex_lingo_name
  defp key(ex_lingo_name, role), do: {ex_lingo_name, role}
end
