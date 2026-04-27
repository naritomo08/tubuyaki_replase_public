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
