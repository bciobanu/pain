defmodule Dashboard.Painting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "painting" do
    field :name, :string
    field :artist, :string
    field :description, :string
    field :image_path, :string
    field :medium, :string
    field :year, :naive_datetime
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(painting, attrs) do
    painting
    |> cast(attrs, [:name, :artist, :medium, :description, :image_path, :year])
    |> validate_required([:name, :artist, :medium, :description, :image_path, :year])
  end
end
