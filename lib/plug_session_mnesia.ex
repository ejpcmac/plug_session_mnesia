defmodule PlugSessionMnesia do
  @moduledoc """
  Application for storing and managing Plug sessions with Mnesia.
  """

  use Application

  alias PlugSessionMnesia.Cleaner

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: PlugSessionMnesia.Supervisor]
    Supervisor.start_link([Cleaner], opts)
  end
end
