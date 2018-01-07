use Mix.Config

config :plug_session_mnesia,
  table: :session,
  max_age: 60,
  cleaner_timeout: 1

# Clear the console before each test run
config :mix_test_watch, clear: true
