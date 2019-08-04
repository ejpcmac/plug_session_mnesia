defmodule PlugSessionMnesia.Cleaner do
  @moduledoc """
  A module to clean inactive sessions.
  """

  use GenServer

  @app :plug_session_mnesia

  @doc """
  Starts the session cleaner.

  `:table` and `:max_age` must be provided in the application configuration for
  this function to work:

      config :plug_session_mnesia,
        table: :session,
        max_age: 86_400

  Returns `{:error, :bad_configuration}` otherwise.
  """
  @spec start_link :: GenServer.on_start()
  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_args \\ nil) do
    with {:ok, table} <- Application.fetch_env(@app, :table),
         {:ok, max_age} <- Application.fetch_env(@app, :max_age) do
      timeout = Application.get_env(:plug_session_mnesia, :cleaner_timeout, 60)
      GenServer.start_link(__MODULE__, {timeout * 1000, table, max_age})
    else
      :error -> {:error, :bad_configuration}
    end
  end

  @impl true
  def init({timeout, _table, _max_age} = args) do
    schedule_work(timeout)
    {:ok, args}
  end

  @impl true
  def handle_info(:work, {timeout, table, max_age} = state) do
    schedule_work(timeout)
    :ok = clean_sessions(table, max_age)
    {:noreply, state}
  end

  @doc """
  Cleans inactive sessions.

  ## Parameters

  * `table` - Mnesia table where sessions are stored
  * `max_age` - maximum age for sessions in seconds

  ## Example

      iex> PlugSessionMnesia.clean_sessions(:session, 86400)
      :ok
  """
  @spec clean_sessions(atom(), pos_integer()) ::
          :ok | {:error | :aborted, term()}

  def clean_sessions(table, max_age) do
    oldest_timestamp =
      System.os_time() - System.convert_time_unit(max_age, :second, :native)

    delete_old_sessions = fn ->
      old_sids =
        :mnesia.select(table, [
          {
            {table, :"$1", :_, :"$3"},
            [{:<, :"$3", oldest_timestamp}],
            [:"$1"]
          }
        ])

      for sid <- old_sids, do: :mnesia.delete({table, sid})
    end

    case :mnesia.transaction(delete_old_sessions) do
      {:atomic, _} -> :ok
      other -> other
    end
  end

  @spec schedule_work(non_neg_integer()) :: reference()
  defp schedule_work(timeout) do
    Process.send_after(self(), :work, timeout)
  end
end
