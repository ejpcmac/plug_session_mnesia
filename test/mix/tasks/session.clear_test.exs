Mix.shell(Mix.Shell.Process)

defmodule Mix.Tasks.Session.ClearTest do
  use PlugSessionMnesia.TestCase

  import Mix.Tasks.Session.Clear

  alias PlugSessionMnesia.TableNotDefined

  describe "run/1" do
    setup [:mnesia, :with_env]

    test "clears all sessions from the store accorting to the configuration" do
      :mnesia.create_table(@table, attributes: [:key, :value])

      record = {@table, :test, :test}
      :mnesia.dirty_write(record)

      assert :mnesia.dirty_match_object({@table, :_, :_}) == [record]
      run([])
      assert :mnesia.dirty_match_object({@table, :_, :_}) == []
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
