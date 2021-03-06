defmodule DashboardWeb.Router do
  use DashboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug DashboardWeb.Plugs.Authenticate
  end

  pipeline :api do
    plug :accepts, ["html"]
  end

  scope "/", DashboardWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/painting", PageController, only: [:new, :create]
    delete "/remove/:id", PageController, :delete

    resources "/session", SessionController, only: [:new, :create]
    delete "/signout", SessionController, :delete

    resources "/register", RegisterController, only: [:new, :create]
  end

  scope "/api", DashboardWeb do
    pipe_through :api

    resources "/predict", PredictorController, only: [:create]
    post "/train", PredictorController, :train
    post "/reload", PredictorController, :reload
    get "/list-museum/:id", PredictorController, :list_museum
  end

  # Other scopes may use custom stacks.
  # scope "/api", DashboardWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  import Phoenix.LiveDashboard.Router

  scope "/" do
    pipe_through :browser
    live_dashboard "/dashboard", metrics: DashboardWeb.Telemetry
  end
end
