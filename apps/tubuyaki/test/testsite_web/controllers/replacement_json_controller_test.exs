defmodule TestsiteWeb.ReplacementJsonControllerTest do
  use TestsiteWeb.ConnCase

  alias Testsite.Accounts

  test "GET /account/stats returns current user totals", %{conn: conn} do
    user = user_fixture("stats")
    {:ok, _tweet} = Testsite.Microblog.create_tweet(%{"content" => "集計"}, user)

    conn =
      conn
      |> Plug.Test.init_test_session(user_id: user.id)
      |> get(~p"/account/stats")

    assert %{"label" => "あなた", "tweet_count" => 1, "like_count" => 0} =
             json_response(conn, 200)
  end

  test "GET /admin/users/list returns users for admin", %{conn: conn} do
    admin = user_fixture("admin")
    user = user_fixture("member")

    conn =
      conn
      |> Plug.Test.init_test_session(user_id: admin.id)
      |> get(~p"/admin/users/list")

    assert %{"users" => users} = json_response(conn, 200)
    assert Enum.any?(users, &(&1["email"] == user.email))
  end

  defp user_fixture(prefix) do
    {:ok, user} =
      Accounts.register_user(%{
        "name" => "#{prefix}_user",
        "email" => "#{prefix}@example.com",
        "password" => "password123"
      })

    user
  end
end
