use Mix.Config

config :dashboard, Dashboard.Repo,
  username: "postgres",
  password: "postgres",
  database: "dashboard",
  hostname: "db",
  port: "5432",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :dashboard, DashboardWeb.Endpoint,
  url: [host: "0.0.0.0", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

secret_key_base = "ct5DbcGH5bXQVFe54QDALHvOe9YYN+V5Is1/eokvZWhAvy+RFOCipR0ajTQ2L+Ea"

config :dashboard, DashboardWeb.Endpoint,
  http: [
    port: 80,
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

config :dashboard, DashboardWeb.Endpoint, server: true
config :dashboard, Phoenix.LiveDashboard, server: true
