defmodule PlugSessionMnesia.MnesiaCase do
  @moduledoc """
  A module for supporting Mnesia requests in the tests.
  """

  defmacro __using__(_opts) do
    quote do
      @table :session_test
      @sid "test_session"
      @data %{key: "value"}
      @new_data %{key: "new_value"}

      defp reset_table(_attrs) do
        case :mnesia.clear_table(@table) do
          {:aborted, {:no_exists, _}} ->
            :mnesia.create_table(@table, [
              attributes: [:sid, :data, :timestamp]
            ])

          ok -> ok
        end

        :ok
      end

      defp with_env(_attrs) do
        Application.put_env(:plug_session_mnesia, :table, @table)
        reset_mnesia()

        on_exit fn ->
          Application.delete_env(:plug_session_mnesia, :table)
          reset_mnesia()
        end
      end

      defp reset_mnesia do
        :mnesia.stop
        :ok = :mnesia.delete_schema([node()])
        File.rm_rf("Mnesia.nonode@nohost")
        :mnesia.start
      end

      defp session_fixture do
        session = {@table, @sid, @data, System.os_time(:nanoseconds)}

        {:atomic, :ok} = :mnesia.transaction fn ->
          :mnesia.write(session)
        end

        session
      end

      defp lookup_session(sid \\ @sid) do
        {:atomic, session} = :mnesia.transaction fn ->
          :mnesia.read({@table, sid})
        end
        session
      end
    end
  end
end
