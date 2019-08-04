use Mix.Config

# Import environment specific config. This must remain at the bottom of this
# file so it overrides the configuration defined above.
unless Mix.env() == :docs do
  import_config "#{Mix.env()}.exs"
end
