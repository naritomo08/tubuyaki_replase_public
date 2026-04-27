defmodule Testsite.Microblog.Tweet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tweets" do
    field :content, :string
    field :like_count, :integer, virtual: true, default: 0
    field :liked_by_demo_user, :boolean, virtual: true, default: false

    belongs_to :user, Testsite.Microblog.User
    has_many :likes, Testsite.Microblog.Like

    many_to_many :images, Testsite.Microblog.Image,
      join_through: "tweet_images",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def changeset(tweet, attrs) do
    tweet
    |> cast(attrs, [:content, :user_id])
    |> validate_required([:content, :user_id])
    |> validate_length(:content, min: 1, max: 255)
    |> foreign_key_constraint(:user_id)
  end
end
