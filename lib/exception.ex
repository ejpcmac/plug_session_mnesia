## This file defines exceptions for plug_session_mnesia

defmodule PlugSessionMnesia.TableNotExists do
  @moduledoc """
  Error raised when `PlugSessionMnesia.Store` tries to access a Mnesia table
  that does not exist.
  """

  defexception []

  def message(_) do
    "the Mnesia table given to the session store does not exist"
  end
end

defmodule PlugSessionMnesia.TableNotDefined do
  @moduledoc """
  Error raised by `PlugSessionMnesia.init!/0` if the Mnesia table is not set in
  the configuration.
  """

  defexception []

  def message(_) do
    """
    Please provide a Mnesia table name in the application configuration:

        config :plug_session_mnesia,
          table: :session
    """
  end
end
