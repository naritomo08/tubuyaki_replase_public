defmodule Testsite.Microblog.Like do
  use Ecto.Schema
  import Ecto.Changeset

  schema "likes" do
    belongs_to :user, Testsite.Microblog.User
    belongs_to :tweet, Testsite.Microblog.Tweet

    timestamps(type: :utc_datetime)
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:user_id, :tweet_id])
    |> validate_required([:user_id, :tweet_id])
    |> unique_constraint([:user_id, :tweet_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:tweet_id)
  end
end
