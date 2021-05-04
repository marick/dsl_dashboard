# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :dsl_dashboard, DslDashboardWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "3wElA8aHxo0F18acplz36VmKdWL1DZQ4u2M7VcRd46r7gs26m4KvqBLqryULxeI6",
  render_errors: [view: DslDashboardWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: DslDashboard.PubSub,
  live_view: [signing_salt: "z4HSJXxX"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
