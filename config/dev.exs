use Mix.Config

config :plug_session_mnesia,
  table: :session,
  max_age: 60,
  cleaner_timeout: 1
