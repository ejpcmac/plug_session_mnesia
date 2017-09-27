defmodule PlugSessionMnesia.StoreTest do
  use ExUnit.Case
  use PlugSessionMnesia.MnesiaCase

  import PlugSessionMnesia.Store

  describe "init/1" do
    test "returns the configuration if it’s OK" do
      assert init(table: @table) == @table
    end

    test "raises if the table is not provided" do
      assert_raise KeyError, fn -> init([]) end
    end
  end

  describe "get/3" do
    setup [:reset_table]

    test "gets the session from the store if it exists" do
      session_fixture()
      assert get(nil, @sid, @table) == {@sid, @data}
    end

    test "updates the access timestamp" do
      {_, _, _, timestamp} = session_fixture()
      get(nil, @sid, @table)
      [{_, _, _, new_timestamp}] = lookup_session()

      assert new_timestamp != timestamp
    end

    test "returns a nil session if it does not exists in the store" do
      assert get(nil, @sid, @table) == {nil, %{}}
    end
  end

  describe "put/4" do
    setup [:reset_table]

    test "puts the session in the store if it exists" do
      session_fixture()
      assert put(nil, @sid, @new_data, @table) == @sid
      assert [{_, @sid, @new_data, _}] = lookup_session()
    end

    test "creates a new session if the store if it does not exists" do
      sid = put(nil, nil, @data, @table)
      assert not is_nil(sid)
      assert [{_, ^sid, @data, _}] = lookup_session(sid)
    end
  end

  describe "delete/3" do
    setup [:reset_table]

    test "deletes the session from the store if it exists" do
      session_fixture()
      assert :ok = delete(nil, @sid, @table)
      assert lookup_session() == []
    end

    test "works as well if the session does not exist" do
      assert :ok = delete(nil, @sid, @table)
    end
  end
end
