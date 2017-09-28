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
