Mix.shell(Mix.Shell.Process)

defmodule Mix.Tasks.Session.SetupTest do
  use ExUnit.Case
  use PlugSessionMnesia.MnesiaCase

  import Mix.Tasks.Session.Setup

  setup [:with_env]

  describe "run/1" do
    test "creates a Mnesia schema and table according to the configuration" do
      run([])

      assert_received {:mix_shell, :info, [msg]}
      assert msg =~ "has been successfully set up for session storage!"
      assert {:aborted, {:already_exists, _}} = :mnesia.create_table(@table, [])
    end

    test "prints an error message if the table name is not provided in the
          configuration" do
      Application.delete_env(:plug_session_mnesia, :table)
      run([])

      assert_received {:mix_shell, :error, [msg]}
      assert msg =~ PlugSessionMnesia.TableNotDefined.message(nil)
    end

    test "prints an error message if a different table already exists with the
          same name" do
      :mnesia.create_table(@table, [attributes: [:id, :data]])
      run([])

      assert_received {:mix_shell, :error, [msg]}
      assert msg =~ PlugSessionMnesia.TableExists.message(%{table: @table})
    end
  end
end
