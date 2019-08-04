use Mix.Config

# Print only warnings and errors during test
config :logger, level: :warn

# Clear the console before each test run
config :mix_test_watch, clear: true

# Configuration for the session cleaner
config :plug_session_mnesia,
  table: :session,
  max_age: 3600,
  # It should never trigger
  cleaner_timeout: 3600
