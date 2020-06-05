defmodule Dashboard.Repo.Migrations.CreateName do
  use Ecto.Migration

  def change do
    create table(:painting) do
      add :name, :string
      add :artist, :string
      add :medium, :string
      add :description, :string
      add :image_path, :string
      add :year, :naive_datetime
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:painting, [:user_id])
  end
end
