defmodule DashboardWeb.Plugs.EnsureUnauthenticated do
  import Plug.Conn
  import Phoenix.Controller

  alias Dashboard.Repo
  alias Dashboard.Auth.User

  def init(_params) do
  end

  def call(conn, _params) do
    if is_nil(conn.assigns.current_user) do
      conn
    else
      conn
      |> put_flash(:info, "You are already logged in.")
      |> redirect(to: DashboardWeb.Router.Helpers.page_path(conn, :index))
    end
  end
end
