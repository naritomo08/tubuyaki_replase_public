defmodule TestsiteWeb.TweetController do
  use TestsiteWeb, :controller

  alias Testsite.Microblog

  def index(conn, params) do
    page = params["page"] || "1"

    render(conn, :index,
      tweets: Microblog.list_tweets(page, conn.assigns.current_user),
      total_count: Microblog.count_tweets(conn.assigns.current_user),
      form: Phoenix.Component.to_form(Microblog.change_tweet(%Testsite.Microblog.Tweet{})),
      page: page,
      query: params["q"] || ""
    )
  end

  def search(conn, %{"q" => query}) do
    render(conn, :index,
      tweets: Microblog.search_tweets(query, conn.assigns.current_user),
      total_count: Microblog.count_tweets(conn.assigns.current_user),
      form: Phoenix.Component.to_form(Microblog.change_tweet(%Testsite.Microblog.Tweet{})),
      page: "1",
      query: query
    )
  end

  def search(conn, _params), do: redirect(conn, to: ~p"/tweet")

  def latest(conn, params) do
    limit = parse_limit(params["limit"])

    json(conn, %{
      total_count: Microblog.count_tweets(conn.assigns.current_user),
      tweets:
        conn.assigns.current_user
        |> Microblog.latest_tweets(limit)
        |> Enum.map(&tweet_json/1)
    })
  end

  def like_status(conn, params) do
    tweet_ids = List.wrap(params["tweet_ids"] || params["tweet_id"] || [])
    json(conn, %{likes: Microblog.like_status(tweet_ids, conn.assigns.current_user)})
  end

  def create(conn, %{"tweet" => tweet_params}) do
    case Microblog.create_tweet(tweet_params, conn.assigns.current_user) do
      {:ok, _tweet} ->
        conn
        |> put_flash(:info, "つぶやきを投稿しました。")
        |> redirect(to: ~p"/tweet")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:index,
          tweets: Microblog.list_tweets("1", conn.assigns.current_user),
          total_count: Microblog.count_tweets(conn.assigns.current_user),
          form: Phoenix.Component.to_form(%{changeset | action: :insert}),
          page: "1",
          query: ""
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    tweet = Microblog.get_tweet!(id)

    render(conn, :edit,
      tweet: tweet,
      form: Phoenix.Component.to_form(Microblog.change_tweet(tweet))
    )
  end

  def update(conn, %{"id" => id, "tweet" => tweet_params}) do
    tweet = Microblog.get_tweet!(id)

    case Microblog.update_tweet(tweet, tweet_params, conn.assigns.current_user) do
      {:ok, _tweet} ->
        conn
        |> put_flash(:info, "つぶやきを更新しました。")
        |> redirect(to: ~p"/tweet")

      {:error, :unauthorized} ->
        conn
        |> put_flash(:error, "自分の投稿だけ編集できます。")
        |> redirect(to: ~p"/tweet")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:edit,
          tweet: tweet,
          form: Phoenix.Component.to_form(%{changeset | action: :update})
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    id
    |> Microblog.get_tweet!()
    |> Microblog.delete_tweet(conn.assigns.current_user)

    conn
    |> put_flash(:info, "つぶやきを削除しました。")
    |> redirect(to: ~p"/tweet")
  end

  def like(conn, %{"id" => id}) do
    Microblog.toggle_like(id, conn.assigns.current_user)
    redirect(conn, to: ~p"/tweet")
  end

  defp tweet_json(tweet) do
    %{
      id: tweet.id,
      content: tweet.content,
      user: %{id: tweet.user.id, name: tweet.user.name},
      like_count: tweet.like_count,
      liked: tweet.liked_by_demo_user,
      is_secret: tweet.is_secret,
      is_protected: tweet.is_protected,
      scheduled_at: format_iso8601(tweet.scheduled_at),
      inserted_at: format_iso8601(tweet.inserted_at),
      images: Enum.map(tweet.images, &%{id: &1.id, url: "/uploads/#{&1.name}"})
    }
  end

  defp format_iso8601(nil), do: nil
  defp format_iso8601(datetime), do: Testsite.DateTime.iso8601_jst(datetime)

  defp parse_limit(value) do
    case Integer.parse(to_string(value || "")) do
      {limit, ""} when limit in 1..100 -> limit
      _ -> 20
    end
  end
end
