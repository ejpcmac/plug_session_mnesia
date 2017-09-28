use Mix.Config

config :plug_session_mnesia,
  table: :session

# Clear the console before each test run
config :mix_test_watch,
  clear: true
