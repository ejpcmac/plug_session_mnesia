defmodule PlugSessionMnesia.CleanerTest do
  use PlugSessionMnesia.TestCase

  alias PlugSessionMnesia.Cleaner

  describe "start_link/1" do
    setup [:reset_env_on_exit]

    test "starts the GenServer if all mandatory configuration is provided" do
      Application.put_env(@app, :table, @table)
      Application.put_env(@app, :max_age, 1)

      assert {:ok, _} = Cleaner.start_link()
    end

    test "fails with an error if the Mnesia table is not provided in the
          configuration" do
      Application.delete_env(@app, :table)
      Application.put_env(@app, :max_age, 1)
      assert {:error, :bad_configuration} = Cleaner.start_link()
    end

    test "fails with an error if the maximum session age is not provided in the
          configuration" do
      Application.put_env(@app, :table, @table)
      Application.delete_env(@app, :max_age)
      assert {:error, :bad_configuration} = Cleaner.start_link()
    end
  end

  describe "clean_sessions/2" do
    setup [:reset_mnesia_table]

    test "cleans old sessions" do
      now = System.os_time()
      one_sec_ago = now - System.convert_time_unit(1, :seconds, :native)
      five_sec_ago = now - System.convert_time_unit(5, :seconds, :native)
      session_a = {@table, "session_a", @data, five_sec_ago}
      session_b = {@table, "session_b", @data, one_sec_ago}

      :ok = :mnesia.dirty_write(session_a)
      :ok = :mnesia.dirty_write(session_b)

      assert :ok = Cleaner.clean_sessions(@table, 2)
      assert :mnesia.dirty_match_object({@table, :_, :_, :_}) == [session_b]
    end

    test "returns an error if something unexpected has occured" do
      :mnesia.delete_table(@table)
      assert {:aborted, {:no_exists, _}} = Cleaner.clean_sessions(@table, 2)
    end
  end

  describe "the cleaner GenServer" do
    setup [:reset_mnesia_table, :reset_env_on_exit]

    test "triggers session cleaning after timeout" do
      Application.put_env(@app, :table, @table)
      Application.put_env(@app, :max_age, 1)
      Application.put_env(@app, :cleaner_timeout, 1)

      now = System.os_time()
      two_sec_ago = now - System.convert_time_unit(2, :seconds, :native)
      old_session = {@table, "old_session", @data, two_sec_ago}
      :ok = :mnesia.dirty_write(old_session)

      assert {:ok, _} = Cleaner.start_link()

      # Wait for the cleaning to trigger
      Process.sleep(1100)

      assert :mnesia.dirty_match_object({@table, :_, :_, :_}) == []
    end
  end

  defp reset_env_on_exit(_) do
    on_exit fn ->
      Application.delete_env(@app, :table)
      Application.delete_env(@app, :max_age)
    end
  end
end
