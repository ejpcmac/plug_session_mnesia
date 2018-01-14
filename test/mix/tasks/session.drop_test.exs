Mix.shell(Mix.Shell.Process)

defmodule Mix.Tasks.Session.DropTest do
  use PlugSessionMnesia.TestCase

  import Mix.Tasks.Session.Drop

  alias PlugSessionMnesia.TableNotDefined

  describe "run/1" do
    setup [:mnesia, :with_env]

    test "drops the Mnesia table accorting to the configuration" do
      :mnesia.create_table(@table, attributes: @attributes)
      run([])

      assert {:aborted, {:no_exists, @table}} = :mnesia.delete_table(@table)
    end

    test "prints an error message if the table name is not provided in the
          configuration" do
      Application.delete_env(@app, :table)
      run([])

      assert_received {:mix_shell, :error, [msg]}
      assert msg =~ TableNotDefined.message(%{})
    end
  end
end
