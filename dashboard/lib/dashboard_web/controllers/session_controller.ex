defmodule DashboardWeb.SessionController do
  use DashboardWeb, :controller

  plug DashboardWeb.Plugs.EnsureUnauthenticated when action not in [:delete]

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"username" => username, "password" => password}}) do
    case Dashboard.Auth.signin(username, password) do
      {:ok, user} ->
        conn
        |> put_session(:current_user_id, user.id)
        |> put_flash(:info, "You have successfully signed in!")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid Email or Password")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end

  def delete(conn, _params) do
    conn
    |> Dashboard.Auth.signout()
    |> redirect(to: Routes.session_path(conn, :new))
  end
end
