defmodule PlugSessionMnesia.Store do
  @moduledoc """
  Stores the session in a Mnesia table.
  """

  @behaviour Plug.Session.Store

  @max_tries 500

  @impl true
  def init(opts) do
    case Application.fetch_env(:plug_session_mnesia, :table) do
      {:ok, table} -> table
      :error -> Keyword.fetch!(opts, :table)
    end
  end

  @impl true
  def get(_conn, sid, table) do
    case lookup_session(table, sid) do
      [{^table, ^sid, data, _timestamp}] ->
        {:atomic, :ok} = put_session(table, sid, data)
        {sid, data}

      _ ->
        {nil, %{}}
    end
  end

  @impl true
  def put(_conn, nil, data, table), do: put_new(table, data)
  def put(_conn, sid, data, table) do
    {:atomic, :ok} = put_session(table, sid, data)
    sid
  end

  @impl true
  def delete(_conn, sid, table) do
    {:atomic, :ok} = :mnesia.transaction fn ->
      :mnesia.delete({table, sid})
    end
    :ok
  end

  defp lookup_session(table, sid) do
    {:atomic, session} = :mnesia.transaction fn ->
      :mnesia.read({table, sid})
    end
    session
  end

  defp put_session(table, sid, data) do
    :mnesia.transaction fn ->
      :mnesia.write({table, sid, data, :os.timestamp})
    end
  end

  defp put_new(table, data, counter \\ 0) when counter < @max_tries do
    sid = Base.encode64(:crypto.strong_rand_bytes(96))
    if lookup_session(table, sid) == [] do
      {:atomic, :ok} = put_session(table, sid, data)
      sid
    else
      put_new(table, data, counter + 1)
    end
  end
end
