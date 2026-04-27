defmodule Testsite.Microblog.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :is_admin, :boolean, default: false
    field :password, :string, virtual: true, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :email_verified_at, :utc_datetime
    field :google_id, :string
    field :google_email, :string
    field :google_avatar, :string
    field :google_connected_at, :utc_datetime
    field :tweets_count, :integer, virtual: true, default: 0
    field :received_likes_count, :integer, virtual: true, default: 0

    has_many :tweets, Testsite.Microblog.Tweet
    has_many :likes, Testsite.Microblog.Like

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :is_admin])
    |> validate_required([:name, :email])
    |> validate_length(:name, min: 1, max: 40)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> put_password_hash()
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
    |> validate_length(:name, min: 1, max: 40)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
  end

  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> put_password_hash()
  end

  def verify_email_changeset(user) do
    change(user, email_verified_at: DateTime.utc_now(:second))
  end

  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password -> put_change(changeset, :password_hash, Testsite.Accounts.hash_password(password))
    end
  end
end
