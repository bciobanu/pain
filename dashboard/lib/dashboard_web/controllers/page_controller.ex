defmodule DashboardWeb.PageController do
  use DashboardWeb, :controller

  plug DashboardWeb.Plugs.EnsureAuthenticated when action in [:index]

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
