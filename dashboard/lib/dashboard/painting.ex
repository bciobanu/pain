defmodule Dashboard.Painting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "name" do
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
    |> cast(attrs, [:artist, :medium, :description, :image_path, :year])
    |> validate_required([:artist, :medium, :description, :image_path, :year])
  end
end
