defmodule TestsiteWeb.AccountHTML do
  use TestsiteWeb, :html

  embed_templates "account_html/*"

  def format_datetime(nil), do: ""

  def format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
end
