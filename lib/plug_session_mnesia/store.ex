defmodule PlugSessionMnesia.Store do
  @moduledoc """
  Stores the session in a Mnesia table.

  The store itself does not create the Mnesia table. It expects an existing
  table to be passed as an argument. You can create it yourself following the
  *Storage* section or use the helpers provided with this application (see
  `PlugSessionMnesia` for more information).

  Since this store uses Mnesia, the session can persist upon restarts and be
  shared between nodes, depending on your configuration.

  ## Options

    * `:table` - Mnesia table name (required if not set in the application
      environment).

  ## Example

      # If you want to create the Mnesia table yourself
      :mnesia.create_schema([node()])
      :mnesia.create_table(:session, [attributes: [:sid, :data, :timestamp], disc_copies: [node()]])
      :mnesia.add_table_index(:session, :timestamp)

      plug Plug.Session,
        key: "_app_key",
        store: PlugSessionMnesia.Store,
        table: :session   # This table must exist.

  ## Storage

  The data is stored in Mnesia in the following format, where `timestamp` is the
  OS UNIX time in the `:native` unit:

      {sid :: String.t, data :: map, timestamp :: integer}

  The timestamp is updated on access to the session and is used by
  `PlugSessionMnesia.Cleaner` to check if the session is still active. If you
  want to delete a session on a fixed amount of time after its creation,
  regardless its activity, you can disable the timestamp update by configuring
  the application:

      config :plug_session_mnesia, timestamp: :fixed
  """

  @behaviour Plug.Session.Store

  alias PlugSessionMnesia.TableNotDefined
  alias PlugSessionMnesia.TableNotExists

  @max_tries 500

  @impl true
  def init(opts) do
    with :error <- Keyword.fetch(opts, :table),
         :error <- Application.fetch_env(:plug_session_mnesia, :table) do
      raise TableNotDefined
    else
      {:ok, table} -> table
    end
  end

  @impl true
  def get(_conn, sid, table) do
    case lookup_session!(table, sid) do
      [{^table, ^sid, data, _timestamp}] ->
        unless Application.get_env(:plug_session_mnesia, :timestamp) == :fixed,
          do: put_session!(table, sid, data, System.os_time())

        {sid, data}

      _ ->
        {nil, %{}}
    end
  end

  @impl true
  def put(_conn, nil, data, table), do: put_new(table, data)

  def put(_conn, sid, data, table) do
    timestamp =
      if Application.get_env(:plug_session_mnesia, :timestamp) == :fixed,
        do: table |> lookup_session!(sid) |> Enum.at(0) |> elem(3),
        else: System.os_time()

    put_session!(table, sid, data, timestamp)
    sid
  end

  @impl true
  def delete(_conn, sid, table) do
    t = fn ->
      :mnesia.delete({table, sid})
    end

    case :mnesia.transaction(t) do
      {:atomic, :ok} -> :ok
      {:aborted, {:no_exists, _}} -> raise TableNotExists
    end
  end

  @spec lookup_session!(atom(), String.t()) :: [
          {atom(), String.t(), map(), integer()}
        ]

  defp lookup_session!(table, sid) do
    t = fn ->
      :mnesia.read({table, sid})
    end

    case :mnesia.transaction(t) do
      {:atomic, session} -> session
      {:aborted, {:no_exists, _}} -> raise TableNotExists
    end
  end

  @spec put_session!(atom(), String.t(), map(), integer()) :: nil
  defp put_session!(table, sid, data, timestamp) do
    t = fn ->
      :mnesia.write({table, sid, data, timestamp})
    end

    case :mnesia.transaction(t) do
      {:atomic, :ok} -> nil
      {:aborted, {:no_exists, _}} -> raise TableNotExists
    end
  end

  @spec put_new(atom(), map()) :: String.t()
  @spec put_new(atom(), map(), non_neg_integer()) :: String.t()
  defp put_new(table, data, counter \\ 0) when counter < @max_tries do
    sid = Base.encode64(:crypto.strong_rand_bytes(96))

    if lookup_session!(table, sid) == [] do
      put_session!(table, sid, data, System.os_time())
      sid
    else
      put_new(table, data, counter + 1)
    end
  end
end
