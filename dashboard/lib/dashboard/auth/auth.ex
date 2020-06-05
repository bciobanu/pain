defmodule Dashboard.Auth do
  alias Dashboard.Repo
  alias Dashboard.Auth.User

  def signin(username, password) do
    user = Repo.get_by(User, username: username)

    cond do
      user && user.password == password ->
        {:ok, user}

      true ->
        {:error, :unauthorized}
    end
  end

  def signout(conn) do
    Plug.Conn.configure_session(conn, drop: true)
  end

  def register(params) do
    User.changeset(%User{}, params) |> Repo.insert()
  end
end
