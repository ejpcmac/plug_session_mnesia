defmodule PlugSessionMnesia.Helpers do
  @moduledoc """
  Helpers for creating the Mnesia table.

  You can use the functions in this module to create the Mnesia table used by
  `PlugSessionMnesia.Store` on the current node. If you want more advanced
  features like distribution, you should create the table yourself.
  """

  @typep persistence() :: :persistent | :volatile
  @typep return_value() :: :ok | {:error | :abort, term()}

  @doc """
  Sets up the Mnesia table for session storage according to the configuration.

  For this function to work, `:table` must be set in your `config.exs`:

      config :plug_session_mnesia,
        table: :session

  It then creates a Mnesia table with copies in RAM and on disk, so that
  sessions are persistent accross application reboots. For more information
  about the process, see `setup/2`.

  If the table already exists *with different attributes*, a
  `PlugSessionMnesia.TableExists` is raised.
  """
  @spec setup! :: :ok
  def setup! do
    fetch_table_name!() |> do_setup!()
  end

  @doc """
  Creates a Mnesia table for the session storage.

  ## Parameters

  * `table` - Mnesia table name
  * `persistent?` - persistence mode. `:persistent` automatically sets the
    schema and the table to keep a copy of their data in both RAM and disk.
    `:volatile` lets the schema copy mode untouched and creates a RAM-only
    session store.

  ## Return values

  * `:ok` - the table has been successfully created
  * `{:error, :already_exists}` - a table with the same name but different
    attribute already exists. If the table has the correct attributes, there is
    no error.
  * Any other error from Mnesia

  ## Examples

      iex> PlugSessionMnesia.Helpers.setup(:session)
      :ok
      iex> :mnesia.create_table(:test, [attributes: [:id, :data]])
      {:atomic, :ok}
      iex> PlugSessionMnesia.Helpers.setup(:test)
      {:error, already_exists}
  """
  @spec setup(atom()) :: return_value()
  @spec setup(atom(), :persistent | :volatile) ::
          :ok | {:error | :abort, term()}

  def setup(table, persistent? \\ :persistent)
      when is_atom(table) and persistent? in [:persistent, :volatile] do
    {:mnesia.start(), persistent?}
    |> create_schema()
    |> create_table(table)
  end

  ##
  ## Private helpers
  ##

  @spec fetch_table_name! :: atom()
  defp fetch_table_name! do
    case Application.fetch_env(:plug_session_mnesia, :table) do
      {:ok, table} -> table
      :error -> raise PlugSessionMnesia.TableNotDefined
    end
  end

  @spec do_setup!(atom()) :: :ok
  defp do_setup!(table) do
    case setup(table) do
      :ok ->
        :ok

      {:error, :table_exists} ->
        raise PlugSessionMnesia.TableExists, table: table
    end
  end

  @spec create_schema({term(), persistence()}) ::
          {return_value(), persistence()}

  defp create_schema({:ok, :persistent} = status) do
    # Just keep it for the else clause.
    node = node()

    with [] <- :mnesia.table_info(:schema, :disc_copies),
         {:atomic, :ok} <- persist_schema() do
      status
    else
      # If the node is already in the disc_copies, alright!
      [^node] ->
        status

      other ->
        {other, :persistent}
    end
  end

  defp create_schema(status), do: status

  @spec persist_schema :: {:atomic, :ok} | {:aborted, term()}
  defp persist_schema,
    do: :mnesia.change_table_copy_type(:schema, node(), :disc_copies)

  @spec create_table({term(), persistence()}, atom()) :: return_value()
  defp create_table({:ok, persistent?}, table) do
    disc_copies =
      if persistent? == :persistent,
        do: [node()],
        else: []

    table_def = [
      attributes: [:sid, :data, :timestamp],
      disc_copies: disc_copies
    ]

    case :mnesia.create_table(table, table_def) do
      {:atomic, :ok} ->
        :ok

      {:aborted, {:already_exists, ^table}} ->
        if :mnesia.table_info(table, :attributes) == [:sid, :data, :timestamp],
          # If the existing table is the same, it’s OK.
          do: :ok,
          else: {:error, :table_exists}
    end
  end

  defp create_table({status, _}, _table), do: status
end
