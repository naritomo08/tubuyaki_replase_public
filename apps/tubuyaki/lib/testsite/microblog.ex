defmodule Testsite.Microblog do
  import Ecto.Query

  alias Testsite.Repo
  alias Testsite.Microblog.{Image, Like, Tweet, User}
  alias Testsite.DateTime, as: AppDateTime

  @demo_user_email "demo@example.com"
  @per_page 50

  def demo_user do
    Repo.get_by(User, email: @demo_user_email) ||
      %User{}
      |> User.changeset(%{name: "demo", email: @demo_user_email})
      |> Repo.insert!()
  end

  def list_tweets(page \\ 1, current_user \\ nil) do
    page = max(parse_positive_integer(page, 1), 1)
    offset = (page - 1) * @per_page

    tweets =
      Tweet
      |> visible_to(current_user)
      |> order_by([t],
        desc: fragment("COALESCE(?, ?)", t.scheduled_at, t.inserted_at),
        desc: t.id
      )
      |> limit(^@per_page)
      |> offset(^offset)
      |> preload([:user, :images])
      |> Repo.all()

    attach_like_state(tweets, current_user && current_user.id)
  end

  def count_tweets(current_user \\ nil) do
    Tweet
    |> visible_to(current_user)
    |> Repo.aggregate(:count)
  end

  def search_tweets(term, current_user) do
    pattern = "%#{String.trim(term || "")}%"

    Tweet
    |> visible_to(current_user)
    |> where([t, author: u], ilike(t.content, ^pattern) or ilike(u.name, ^pattern))
    |> order_by([t], desc: fragment("COALESCE(?, ?)", t.scheduled_at, t.inserted_at), desc: t.id)
    |> preload([:user, :images])
    |> Repo.all()
    |> attach_like_state(current_user && current_user.id)
  end

  def latest_tweets(current_user, limit \\ 20) do
    Tweet
    |> visible_to(current_user)
    |> order_by([t], desc: fragment("COALESCE(?, ?)", t.scheduled_at, t.inserted_at), desc: t.id)
    |> limit(^limit)
    |> preload([:user, :images])
    |> Repo.all()
    |> attach_like_state(current_user && current_user.id)
  end

  def like_status(tweet_ids, current_user) do
    tweet_ids = Enum.map(tweet_ids, &parse_positive_integer(&1, 0)) |> Enum.reject(&(&1 == 0))

    like_counts =
      Like
      |> where([l], l.tweet_id in ^tweet_ids)
      |> group_by([l], l.tweet_id)
      |> select([l], {l.tweet_id, count(l.id)})
      |> Repo.all()
      |> Map.new()

    liked_tweet_ids =
      case current_user do
        %User{} ->
          Like
          |> where([l], l.user_id == ^current_user.id and l.tweet_id in ^tweet_ids)
          |> select([l], l.tweet_id)
          |> Repo.all()
          |> MapSet.new()

        _ ->
          MapSet.new()
      end

    Enum.map(tweet_ids, fn tweet_id ->
      %{
        tweet_id: tweet_id,
        like_count: Map.get(like_counts, tweet_id, 0),
        liked: MapSet.member?(liked_tweet_ids, tweet_id)
      }
    end)
  end

  def list_scheduled_tweets(%User{} = user) do
    Tweet
    |> where([t], t.user_id == ^user.id)
    |> where([t], not is_nil(t.scheduled_at) and t.scheduled_at > ^DateTime.utc_now(:second))
    |> order_by([t], asc: t.scheduled_at)
    |> preload([:user])
    |> Repo.all()
  end

  def list_scheduled_tweets(:all) do
    Tweet
    |> where([t], not is_nil(t.scheduled_at) and t.scheduled_at > ^DateTime.utc_now(:second))
    |> order_by([t], asc: t.scheduled_at)
    |> preload([:user])
    |> Repo.all()
  end

  def get_tweet!(id) do
    Tweet
    |> Repo.get!(id)
    |> Repo.preload([:user, :images])
  end

  def change_tweet(%Tweet{} = tweet, attrs \\ %{}) do
    Tweet.changeset(tweet, attrs)
  end

  def create_tweet(attrs, %User{} = user) do
    attrs =
      attrs
      |> normalize_tweet_attrs()
      |> Map.put("user_id", user.id)

    Repo.transaction(fn ->
      tweet =
        %Tweet{}
        |> Tweet.changeset(attrs)
        |> Repo.insert!()

      save_images(tweet, Map.get(attrs, "images", []))
      tweet
    end)
    |> unwrap_transaction()
  end

  def create_tweet(attrs), do: create_tweet(attrs, demo_user())

  def update_tweet(%Tweet{} = tweet, attrs, %User{} = user) do
    if owns_tweet?(tweet, user) or user.is_admin do
      Repo.transaction(fn ->
        updated_tweet =
          tweet
          |> Tweet.changeset(normalize_tweet_attrs(attrs))
          |> Repo.update!()

        save_images(updated_tweet, Map.get(attrs, "images", []))
        updated_tweet
      end)
      |> unwrap_transaction()
    else
      {:error, :unauthorized}
    end
  end

  def update_tweet(%Tweet{} = tweet, attrs) do
    tweet
    |> Tweet.changeset(normalize_tweet_attrs(attrs))
    |> Repo.update()
  end

  def delete_tweet(%Tweet{} = tweet, %User{} = user) do
    if owns_tweet?(tweet, user) or user.is_admin do
      Repo.delete(tweet)
    else
      {:error, :unauthorized}
    end
  end

  def delete_tweet(%Tweet{} = tweet), do: Repo.delete(tweet)

  def toggle_like(tweet_id, %User{} = user) do
    user_id = user.id

    case Repo.get_by(Like, user_id: user_id, tweet_id: tweet_id) do
      nil ->
        %Like{}
        |> Like.changeset(%{user_id: user_id, tweet_id: tweet_id})
        |> Repo.insert()

      like ->
        Repo.delete(like)
    end
  end

  def toggle_like(tweet_id), do: toggle_like(tweet_id, demo_user())

  def owns_tweet?(%Tweet{} = tweet, %User{} = user), do: tweet.user_id == user.id
  def owns_tweet?(_, _), do: false

  def user_stats(%User{} = user) do
    tweet_count = from(t in Tweet, where: t.user_id == ^user.id) |> Repo.aggregate(:count)

    like_count =
      from(l in Like,
        join: t in assoc(l, :tweet),
        where: t.user_id == ^user.id
      )
      |> Repo.aggregate(:count)

    %{tweet_count: tweet_count, like_count: like_count}
  end

  def total_like_count, do: Repo.aggregate(Like, :count)

  defp attach_like_state(tweets, user_id) do
    tweet_ids = Enum.map(tweets, & &1.id)

    like_counts =
      Like
      |> where([l], l.tweet_id in ^tweet_ids)
      |> group_by([l], l.tweet_id)
      |> select([l], {l.tweet_id, count(l.id)})
      |> Repo.all()
      |> Map.new()

    liked_tweet_ids =
      if user_id do
        Like
        |> where([l], l.user_id == ^user_id and l.tweet_id in ^tweet_ids)
        |> select([l], l.tweet_id)
        |> Repo.all()
        |> MapSet.new()
      else
        MapSet.new()
      end

    Enum.map(tweets, fn tweet ->
      %{
        tweet
        | like_count: Map.get(like_counts, tweet.id, 0),
          liked_by_demo_user: MapSet.member?(liked_tweet_ids, tweet.id)
      }
    end)
  end

  defp normalize_tweet_attrs(attrs) do
    content =
      attrs
      |> Map.get("content", Map.get(attrs, :content, ""))
      |> String.trim()

    attrs
    |> Map.put("content", content)
    |> normalize_checkbox("is_secret")
    |> normalize_checkbox("is_protected")
    |> normalize_scheduled_at()
  end

  defp visible_to(query, %User{is_admin: true}) do
    query
    |> exclude_deleted_users()
    |> published_or_scheduled_owner(nil, true)
  end

  defp visible_to(query, %User{} = user) do
    query
    |> exclude_deleted_users()
    |> published_or_scheduled_owner(user.id, false)
    |> where([t], t.is_secret == false or t.user_id == ^user.id)
  end

  defp visible_to(query, nil) do
    query
    |> exclude_deleted_users()
    |> published_or_scheduled_owner(nil, false)
    |> where([t], t.is_secret == false)
  end

  defp exclude_deleted_users(query) do
    query
    |> join(:inner, [t], u in assoc(t, :user), as: :author)
    |> where([author: u], is_nil(u.deletion_requested_at))
  end

  defp published_or_scheduled_owner(query, _user_id, true), do: query

  defp published_or_scheduled_owner(query, nil, false) do
    now = DateTime.utc_now(:second)
    where(query, [t], is_nil(t.scheduled_at) or t.scheduled_at <= ^now)
  end

  defp published_or_scheduled_owner(query, user_id, false) do
    now = DateTime.utc_now(:second)
    where(query, [t], is_nil(t.scheduled_at) or t.scheduled_at <= ^now or t.user_id == ^user_id)
  end

  defp normalize_checkbox(attrs, key) do
    Map.put(attrs, key, Map.get(attrs, key) in [true, "true", "1", 1, "on"])
  end

  defp normalize_scheduled_at(attrs) do
    scheduled_at =
      attrs
      |> Map.get("scheduled_at", Map.get(attrs, :scheduled_at))
      |> parse_datetime()

    Map.put(attrs, "scheduled_at", scheduled_at)
  end

  defp parse_datetime(value), do: AppDateTime.from_jst_datetime_local(value)

  defp save_images(_tweet, []), do: :ok
  defp save_images(_tweet, nil), do: :ok

  defp save_images(tweet, uploads) when is_list(uploads) do
    Enum.each(uploads, &save_image(tweet, &1))
  end

  defp save_image(_tweet, %Plug.Upload{filename: ""}), do: :ok

  defp save_image(tweet, %Plug.Upload{} = upload) do
    upload_dir = Path.join([:code.priv_dir(:testsite), "static", "uploads"])
    File.mkdir_p!(upload_dir)

    extension = upload.filename |> Path.extname() |> String.downcase()
    name = "#{System.unique_integer([:positive])}-#{Ecto.UUID.generate()}#{extension}"
    destination = Path.join(upload_dir, name)
    File.cp!(upload.path, destination)

    image =
      %Image{}
      |> Image.changeset(%{name: name})
      |> Repo.insert!()

    tweet = Repo.preload(tweet, :images)

    tweet
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:images, [image | tweet.images])
    |> Repo.update!()
  end

  defp save_image(_tweet, _upload), do: :ok

  defp unwrap_transaction({:ok, value}), do: {:ok, value}
  defp unwrap_transaction({:error, reason}), do: {:error, reason}

  defp parse_positive_integer(value, fallback) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> integer
      _ -> fallback
    end
  end

  defp parse_positive_integer(value, _fallback) when is_integer(value), do: value
  defp parse_positive_integer(_value, fallback), do: fallback
end
