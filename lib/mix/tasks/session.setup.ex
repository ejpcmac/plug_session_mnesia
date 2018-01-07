defmodule Mix.Tasks.Session.Setup do
  use Mix.Task

  @shortdoc "Creates the Mnesia table for :plug_session_mnesia"

  @moduledoc """
  Creates the Mnesia table for `:plug_session_mnesia`.

  To set up the Mnesia table for session storage, configure it in your
  `config.exs`:

      config :plug_session_mnesia,
        table: :session

  Then, simply run this mix task:

      mix session.setup

  If you use to start your IEx development sessions with a node name, you must
  also run `session.setup` with the same node name to effictively create the
  Mnesia table on the good node:

      elixir --sname "my_node@my_host" -S mix session.setup

  ## Configuration

  By default, the Mnesia files will be stored in `Mnesia.nonode@nohost` in your
  project directory. You can add this directory to your `.gitignore`. If you
  want to store them elsewhere, you can configure Mnesia in your `config.exs`:

      config :mnesia,
        dir: 'path/to/dir'  # Note the simple quotes, Erlang strings are charlists ;-)

  For more information about Mnesia and its configuration, please see `:mnesia`
  in the Erlang documentation.
  """

  @spec run(OptionParser.argv()) :: boolean()
  def run(_argv) do
    PlugSessionMnesia.Helpers.setup!()
    table = Application.fetch_env!(:plug_session_mnesia, :table)

    Mix.shell().info(
      IO.ANSI.green() <>
        "The Mnesia table '#{table}' has been successfully set up for " <>
        "session storage!"
    )
  rescue
    e in PlugSessionMnesia.TableNotDefined ->
      Mix.shell().error(PlugSessionMnesia.TableNotDefined.message(e))

    e in PlugSessionMnesia.TableExists ->
      Mix.shell().error(PlugSessionMnesia.TableExists.message(e))
  end
end
