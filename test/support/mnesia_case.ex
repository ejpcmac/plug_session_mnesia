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

      defp session_fixture do
        session = {@table, @sid, @data, :os.timestamp}

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
