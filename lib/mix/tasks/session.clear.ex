defmodule Mix.Tasks.Session.Clear do
  use Mix.Task

  @shortdoc "Clears all sessions from the Mnesia table"

  @moduledoc """
  Clears all sessions from the Mnesia table.

  To clear all sessions from the Mnesia table, run this mix task:

      $ mix session.clear

  If you use to start your IEx development sessions with a node name, you must
  also run `session.clear` with the same node name to effictively run the
  command on the good Mnesia database:

      $ elixir --sname "my_node@my_host" -S mix session.clear
  """

  alias PlugSessionMnesia.Helpers
  alias PlugSessionMnesia.TableNotDefined

  @spec run(OptionParser.argv()) :: boolean()
  def run(_argv) do
    Helpers.clear!()
  rescue
    e in TableNotDefined -> Mix.shell().error(TableNotDefined.message(e))
  end
end
