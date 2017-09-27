## This file defines exceptions for plug_session_mnesia

defmodule PlugSessionMnesia.TableNotExists do
  defexception []

  def message(_) do
    "the Mnesia table given to the session store does not exist"
  end
end
