defmodule TestsiteWeb.PageControllerTest do
  use TestsiteWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/tweet"
  end
end
