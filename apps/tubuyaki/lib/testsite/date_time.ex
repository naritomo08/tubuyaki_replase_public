defmodule Testsite.DateTime do
  @jst_offset_seconds 9 * 60 * 60

  def from_jst_datetime_local(nil), do: nil
  def from_jst_datetime_local(""), do: nil
  def from_jst_datetime_local(%DateTime{} = datetime), do: datetime

  def from_jst_datetime_local(%NaiveDateTime{} = datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.add(-@jst_offset_seconds, :second)
  end

  def from_jst_datetime_local(value) when is_binary(value) do
    value = String.trim(value)

    with {:error, _} <- DateTime.from_iso8601(value),
         {:ok, naive_datetime} <- parse_naive_datetime(value) do
      from_jst_datetime_local(naive_datetime)
    else
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  def to_jst(%DateTime{} = datetime), do: DateTime.add(datetime, @jst_offset_seconds, :second)

  def to_jst(%NaiveDateTime{} = datetime),
    do: DateTime.add(datetime, @jst_offset_seconds, :second)

  def to_jst(nil), do: nil

  def format_jst(nil), do: ""

  def format_jst(datetime) do
    datetime
    |> to_jst()
    |> Calendar.strftime("%Y-%m-%d %H:%M")
  end

  def iso8601_jst(nil), do: nil

  def iso8601_jst(datetime) do
    datetime
    |> to_jst()
    |> Calendar.strftime("%Y-%m-%dT%H:%M:%S")
  end

  defp parse_naive_datetime(value) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, datetime} -> {:ok, datetime}
      {:error, _} -> NaiveDateTime.from_iso8601(value <> ":00")
    end
  end
end
