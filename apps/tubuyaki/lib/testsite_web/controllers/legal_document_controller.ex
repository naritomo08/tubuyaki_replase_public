defmodule TestsiteWeb.LegalDocumentController do
  use TestsiteWeb, :controller

  def terms(conn, _params), do: render(conn, :terms)
  def privacy(conn, _params), do: render(conn, :privacy)
end
