defmodule Dashboard.Auth.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :password, :string
    field :username, :string
    field :password_confirmation, :string, virtual: true
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_length(:password, min: 4, max: 128)
    |> validate_confirmation(:password)
    |> unique_constraint(:username)
  end
end
