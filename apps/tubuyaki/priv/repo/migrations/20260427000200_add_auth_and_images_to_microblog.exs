defmodule Testsite.Repo.Migrations.AddAuthAndImagesToMicroblog do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :password_hash, :string
      add :email_verified_at, :utc_datetime
      add :google_id, :string
      add :google_email, :string
      add :google_avatar, :text
      add :google_connected_at, :utc_datetime
    end

    create unique_index(:users, [:google_id])

    create table(:images) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:tweet_images, primary_key: false) do
      add :tweet_id, references(:tweets, on_delete: :delete_all), null: false
      add :image_id, references(:images, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tweet_images, [:tweet_id, :image_id])
    create index(:tweet_images, [:image_id])
  end
end
