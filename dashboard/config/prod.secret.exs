# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

database_url = "ecto://postgres:postgres@db/dashboard"

config :dashboard, Dashboard.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base = "4Pel0UxWPqYLTv1D5AUx2pLuI07/n+W9/B4LyQ7XrG4odoKoaJ1k6kBhR3Y5n/kI"

config :dashboard, DashboardWeb.Endpoint,
  http: [
    port: String.to_integer("80"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

config :dashboard, DashboardWeb.Endpoint, server: true

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :dashboard, DashboardWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
