defmodule TestsiteWeb.AuthControllerTest do
  use TestsiteWeb.ConnCase

  test "register creates a user and logs in", %{conn: conn} do
    conn =
      post(conn, ~p"/register",
        user: %{name: "newuser", email: "new@example.com", password: "password123"}
      )

    assert redirected_to(conn) == ~p"/tweet"
    assert get_session(conn, :user_id)
  end
end
