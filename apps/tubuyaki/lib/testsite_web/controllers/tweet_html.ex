defmodule TestsiteWeb.TweetHTML do
  use TestsiteWeb, :html

  embed_templates "tweet_html/*"

  def format_datetime(nil), do: ""

  def format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
end
