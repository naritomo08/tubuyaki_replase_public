defmodule TestsiteWeb.TweetControllerTest do
  use TestsiteWeb.ConnCase

  alias Testsite.Accounts

  test "GET /tweet renders the Phoenix tweet app", %{conn: conn} do
    conn = get(conn, ~p"/tweet")

    assert html_response(conn, 200) =~ "つぶやきアプリ"
  end

  test "GET /tweet renders the tweet form for logged-in users", %{conn: conn} do
    user = user_fixture()
    conn = Plug.Test.init_test_session(conn, user_id: user.id)

    conn = get(conn, ~p"/tweet")

    assert html_response(conn, 200) =~ "いまどうしてる？"
  end

  test "POST /tweet creates a tweet", %{conn: conn} do
    user = user_fixture()
    conn = Plug.Test.init_test_session(conn, user_id: user.id)

    conn = post(conn, ~p"/tweet", tweet: %{content: "Phoenixで投稿"})

    assert redirected_to(conn) == ~p"/tweet"
    assert Testsite.Microblog.count_tweets() == 1
  end

  test "GET /tweet/latest returns visible tweets as json", %{conn: conn} do
    user = user_fixture()
    {:ok, _tweet} = Testsite.Microblog.create_tweet(%{"content" => "JSONで取得"}, user)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> get(~p"/tweet/latest")

    assert %{"total_count" => 1, "tweets" => [%{"content" => "JSONで取得", "like_count" => 0}]} =
             json_response(conn, 200)
  end

  test "GET /like/status returns counts and liked state", %{conn: conn} do
    user = user_fixture()
    {:ok, tweet} = Testsite.Microblog.create_tweet(%{"content" => "いいね確認"}, user)

    conn =
      conn
      |> Plug.Test.init_test_session(user_id: user.id)
      |> post(~p"/tweet/#{tweet.id}/like")

    conn = get(recycle(conn), ~p"/like/status", tweet_ids: [tweet.id])
    tweet_id = tweet.id

    assert %{"likes" => [%{"tweet_id" => ^tweet_id, "like_count" => 1, "liked" => true}]} =
             json_response(conn, 200)
  end

  test "scheduled_at keeps the JST time selected by the user", %{conn: conn} do
    user = user_fixture()
    conn = Plug.Test.init_test_session(conn, user_id: user.id)

    conn =
      post(conn, ~p"/tweet", tweet: %{content: "予約投稿", scheduled_at: "2026-06-07T20:30"})

    assert redirected_to(conn) == ~p"/tweet"
    [tweet] = Testsite.Microblog.list_scheduled_tweets(user)
    assert DateTime.to_iso8601(tweet.scheduled_at) == "2026-06-07T11:30:00Z"

    conn =
      conn
      |> recycle()
      |> Plug.Test.init_test_session(user_id: user.id)
      |> put_req_header("accept", "application/json")
      |> get(~p"/tweet/latest")

    assert %{"tweets" => [%{"scheduled_at" => "2026-06-07T20:30:00"} | _]} =
             json_response(conn, 200)
  end

  defp user_fixture do
    {:ok, user} =
      Accounts.register_user(%{
        "name" => "testuser",
        "email" => "test@example.com",
        "password" => "password123"
      })

    user
  end
end
