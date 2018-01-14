defmodule PlugSessionMnesia do
  @moduledoc """
  An application for storing and managing Plug sessions with Mnesia.

  This application provides a `Plug.Session.Store` using Mnesia as back-end, and
  a session cleaner for automatically deleting inactive sessions. It also
  provide helpers for creating the Mnesia table.

  Using Mnesia enables session persistence between application reboots and
  distribution. However, distribution is not yet supported out of the box by the
  table creation helpers. You must create the Mnesia table yourself to use this
  feature.

  ## Setup

  To use it in your app, add this to your dependencies:

      {:plug_session_mnesia, "~> #{Mix.Project.config()[:version]}"}

  Then, add to your configuration:

      config :plug_session_mnesia,
        table: :session,
        max_age: 86_400

  It will store the sessions in a Mnesia table named `session` and discard them
  if they are inactive for more than 1 day. You can also choose to discard
  sessions after a given amount of time, regardless they have been active or
  not. To do this, simply add `timestamp: :fixed` to the configuration.

  By default, `PlugSessionMnesia.Cleaner` checks every minute for outdated
  sessions. You can change this behaviour by setting the `:cleaner_timeout` key
  in the configuration with a value in seconds.

  You must also tell `Plug.Session` that you use this store:

      plug Plug.Session,
        key: "_app_key",
        store: PlugSessionMnesia.Store

  You can then create the Mnesia table:

      $ mix session.setup

  If you want to use a node name or a custom directory for the Mnesia database,
  you can take a look at `Mix.Tasks.Session.Setup`.

  You can also create it directly from Elixir using
  `PlugSessionMnesia.Helpers.setup!/0`. This can be useful to include in a setup
  task to be run in a release environment.
  """

  use Application

  alias PlugSessionMnesia.Cleaner

  @impl true
  def start(_type, _args) do
    Supervisor.start_link(
      [Cleaner],
      strategy: :one_for_one,
      name: PlugSessionMnesia.Supervisor
    )
  end
end
