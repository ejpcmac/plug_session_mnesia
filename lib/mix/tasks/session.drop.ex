defmodule Mix.Tasks.Session.Drop do
  use Mix.Task

  @shortdoc "Clears all sessions from the Mnesia table"

  @moduledoc """
  Drops the Mnesia table.

  To drop the Mnesia table, run this mix task:

      $ mix session.drop

  If you use to start your IEx development sessions with a node name, you must
  also run `session.drop` with the same node name to effictively run the
  command on the good Mnesia database:

      $ elixir --sname "my_node@my_host" -S mix session.drop
  """

  alias PlugSessionMnesia.Helpers
  alias PlugSessionMnesia.TableNotDefined

  @spec run(OptionParser.argv()) :: boolean()
  def run(_argv) do
    Helpers.drop!()
  rescue
    e in TableNotDefined -> Mix.shell().error(TableNotDefined.message(e))
  end
end
