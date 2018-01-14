defmodule PlugSessionMnesia.TestCase do
  @moduledoc """
  A test case for `PlugSessionMnesia`.

  This module provides helpers for testing the application.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @app :plug_session_mnesia
      @table :session_test
      @attributes [:sid, :data, :timestamp]
      @sid "test_session"
      @data %{key: "value"}
      @new_data %{key: "new_value"}

      defp reset_mnesia_table(_attrs) do
        case :mnesia.clear_table(@table) do
          {:aborted, {:no_exists, _}} ->
            :mnesia.create_table(@table, attributes: @attributes)

          ok ->
            ok
        end

        :ok
      end

      defp mnesia(_attrs) do
        reset_mnesia()
        on_exit(fn -> reset_mnesia() end)
      end

      defp with_env(_attrs) do
        Application.put_env(@app, :table, @table)
        on_exit(fn -> Application.delete_env(@app, :table) end)
      end

      defp reset_mnesia do
        :mnesia.stop()
        :ok = :mnesia.delete_schema([node()])
        File.rm_rf("Mnesia.nonode@nohost")
        :mnesia.start()
      end

      defp session_fixture do
        session = {@table, @sid, @data, System.os_time()}
        :ok = :mnesia.dirty_write(session)
        session
      end

      defp lookup_session(sid \\ @sid) do
        :mnesia.dirty_read({@table, sid})
      end
    end
  end
end
