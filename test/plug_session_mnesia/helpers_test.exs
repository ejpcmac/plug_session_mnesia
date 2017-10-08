defmodule PlugSessionMnesia.HelpersTest do
  use PlugSessionMnesia.TestCase

  alias PlugSessionMnesia.Helpers

  setup [:mnesia, :with_env]

  describe "setup!/0" do
    test "creates a Mnesia schema and table according to the configuration" do
      assert :ok = Helpers.setup!
      assert {:aborted, {:already_exists, _}} = :mnesia.create_table(@table, [])
      assert :mnesia.table_info(@table, :attributes) ==
        [:sid, :data, :timestamp]
    end

    test "raises if the table name is not provided in the configuration" do
      Application.delete_env(@app, :table)

      assert_raise PlugSessionMnesia.TableNotDefined, fn ->
        Helpers.setup!
      end
    end

    test "raises if a different table already exists with the same name" do
      :mnesia.create_table(@table, [attributes: [:id, :data]])

      assert_raise PlugSessionMnesia.TableExists, fn ->
        Helpers.setup!
      end
    end

    test "does nothing if the table already exists" do
      :mnesia.create_table(@table, [attributes: [:sid, :data, :timestamp]])
      assert :ok = Helpers.setup!
    end
  end

  describe "setup/3" do
    test "creates a Mnesia schema and table and returns :ok if it’s all good" do
      assert :ok = Helpers.setup(@table)
      assert {:aborted, {:already_exists, _}} = :mnesia.create_table(@table, [])
      assert :mnesia.table_info(@table, :attributes) ==
        [:sid, :data, :timestamp]
    end

    test "can create a persistent table" do
      filename = Atom.to_string(@table) <> ".DCD"
      assert :ok = Helpers.setup(@table, :persistent)
      assert "Mnesia.nonode@nohost" |> Path.join(filename) |> File.exists?
    end

    test "can create a volatile table" do
      assert :ok = Helpers.setup(@table, :volatile)
      assert not (
        "Mnesia.nonode@nohost"
        |> Path.join("test.DCD")
        |> File.exists?
      )
    end

    test "works if a persistent schema already exists" do
      {:atomic, :ok} =
        :mnesia.change_table_copy_type(:schema, node(), :disc_copies)

      assert :ok = Helpers.setup(@table)
    end

    test "returns an error if the schema cannot be written on disk" do
      File.touch("Mnesia.nonode@nohost")
      assert {:aborted, _} = Helpers.setup(@table)
    end

    test "returns {:error | :aborted, reason} if an error occured" do
      :mnesia.create_table(@table, [])
      assert {:error, _} = Helpers.setup(@table)
    end
  end
end
