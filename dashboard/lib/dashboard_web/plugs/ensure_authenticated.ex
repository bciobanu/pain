defmodule DashboardWeb.Plugs.EnsureAuthenticated do
  import Plug.Conn
  import Phoenix.Controller

  def init(_params) do
  end

  def call(conn, _params) do
    unless is_nil(conn.assigns.current_user) do
      conn
    else
      conn
      |> put_flash(:error, "You need to sign in or sign up before continuing.")
      |> redirect(to: DashboardWeb.Router.Helpers.session_path(conn, :new))
      |> halt()
    end
  end
end
