defmodule ExLingo.Utils.DatabasePopulator do
  @moduledoc false

  import Ecto.Changeset

  alias ExLingo.Repo
  alias ExLingo.Utils.GetSchemata

  @resource_name_to_schema GetSchemata.call()
                           |> Map.new()

  @allowed_keys ~w(
    id name description color iso639_code native_name family wiki_url colors plurals_header
    msgid context message_type domain_id locale_id message_id
    original_text translated_text nplural_index source_references context_review_requested_at
    context_review_context inserted_at updated_at
  )
  @allowed_key_map Map.new(@allowed_keys, &{&1, String.to_atom(&1)})

  @spec call(module(), String.t(), [map()]) :: {:ok, non_neg_integer()} | {:error, term()}
  def call(repo \\ Repo.get_repo(), resource_name, entries) do
    with {:ok, schema} <- fetch_schema(resource_name),
         true <- is_list(entries) || {:error, {:invalid_entries, entries}} do
      Enum.reduce_while(entries, {:ok, 0}, &populate_entry(repo, schema, &1, &2))
    end
  end

  defp populate_entry(repo, schema, entry, {:ok, count}) do
    case populate(repo, schema, entry) do
      {:ok, _record} -> {:cont, {:ok, count + 1}}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp fetch_schema(resource_name) do
    case @resource_name_to_schema[resource_name] do
      nil -> {:error, {:unknown_resource, resource_name}}
      schema -> {:ok, schema}
    end
  end

  defp populate(_repo, _schema, entry) when not is_map(entry) do
    {:error, {:invalid_entry, entry}}
  end

  defp populate(repo, %{schema: schema, conflict_target: conflict_target}, entry) do
    with {:ok, attrs} <- keys_to_atoms(entry) do
      schema
      |> struct()
      |> change(attrs)
      |> repo.insert(Repo.opts(on_conflict: :replace_all, conflict_target: conflict_target))
    end
  end

  defp keys_to_atoms(map) do
    Enum.reduce_while(map, {:ok, %{}}, fn entry, {:ok, acc} ->
      case reduce_keys_to_atoms(entry) do
        {:ok, {key, value}} -> {:cont, {:ok, Map.put(acc, key, value)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp reduce_keys_to_atoms({"message_type", "singular"}) do
    {:ok, {:message_type, :singular}}
  end

  defp reduce_keys_to_atoms({"message_type", "plural"}) do
    {:ok, {:message_type, :plural}}
  end

  defp reduce_keys_to_atoms({key, val}) when is_binary(key) do
    with {:ok, atom_key} <- atom_key(key),
         {:ok, value} <- convert_value(val) do
      {:ok, {atom_key, value}}
    end
  end

  defp reduce_keys_to_atoms({key, val}) do
    with {:ok, value} <- convert_value(val) do
      {:ok, {key, value}}
    end
  end

  defp atom_key(key) do
    case @allowed_key_map[key] do
      nil -> {:error, {:unknown_key, key}}
      atom -> {:ok, atom}
    end
  end

  defp convert_value(val) when is_map(val), do: keys_to_atoms(val)

  defp convert_value(val) when is_list(val) do
    Enum.reduce_while(val, {:ok, []}, fn
      item, {:ok, acc} when is_map(item) ->
        case keys_to_atoms(item) do
          {:ok, value} -> {:cont, {:ok, [value | acc]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end

      item, {:ok, acc} ->
        {:cont, {:ok, [item | acc]}}
    end)
    |> case do
      {:ok, items} -> {:ok, Enum.reverse(items)}
      error -> error
    end
  end

  defp convert_value(val), do: {:ok, val}
end
