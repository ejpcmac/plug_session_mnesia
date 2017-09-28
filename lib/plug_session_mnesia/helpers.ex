defmodule PlugSessionMnesia.Helpers do
  @moduledoc """
  Helpers for creating the Mnesia table.
  """

  @typep persistence :: :persistent | :volatile
  @typep return_value :: :ok | {:error | :abort, term}

  @doc """
  Sets the Mnesia table up for session storage according to the configuration.
  """
  @spec setup! :: :ok
  def setup! do
    fetch_table_name!() |> do_setup!()
  end

  @doc """
  Creates a Mnesia `table` for the session storage on the specified `nodes`.
  """
  @spec setup(atom) :: return_value
  @spec setup(atom, :persistent | :volatile) :: :ok | {:error | :abort, term}
  def setup(table, persistent? \\ :persistent)
      when is_atom(table) and persistent? in [:persistent, :volatile] do
    {:mnesia.start, persistent?}
    |> create_schema()
    |> create_table(table)
  end

  ##
  ## Private helpers
  ##

  @spec fetch_table_name! :: atom
  defp fetch_table_name! do
    case Application.fetch_env(:plug_session_mnesia, :table) do
      {:ok, table} -> table
      :error -> raise PlugSessionMnesia.TableNotDefined
    end
  end

  @spec do_setup!(atom) :: :ok
  defp do_setup!(table) do
    case setup(table) do
      :ok -> :ok

      {:error, :table_exists} ->
        raise PlugSessionMnesia.TableExists, table: table
    end
  end

  @spec create_schema({term, persistence}) :: {return_value, persistence}
  defp create_schema({:ok, :persistent} = status) do
    node = node()   # Just keep it for the else clause.

    with [] <- :mnesia.table_info(:schema, :disc_copies),
         {:atomic, :ok} <- persist_schema() do
      status
    else
      [^node] -> status   # If the node is already in the disc_copies, alright!
      other -> {other, :persistent}
    end
  end
  defp create_schema(status), do: status

  @spec persist_schema :: {:atomic, :ok} | {:aborted, term}
  defp persist_schema,
    do: :mnesia.change_table_copy_type(:schema, node(), :disc_copies)

  @spec create_table({term, persistence}, atom) :: return_value
  defp create_table({:ok, persistent?}, table) do
    disc_copies =
      if persistent? == :persistent,
        do: [node()],
      else: []

    table_def = [
      attributes: [:sid, :data, :timestamp],
      disc_copies: disc_copies,
    ]

    case :mnesia.create_table(table, table_def) do
      {:atomic, :ok} ->
        :ok

      {:aborted, {:already_exists, ^table}} ->
        if :mnesia.table_info(table, :attributes) == [:sid, :data, :timestamp],
          do: :ok,  # If the existing table is the same, it’s OK.
        else: {:error, :table_exists}
    end
  end
  defp create_table({status, _}, _table), do: status
end
