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
end
