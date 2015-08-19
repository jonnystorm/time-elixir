defmodule Time do
  @type date :: {pos_integer, 1..12, 1..31}
  @type time :: {0..23, 0..59, 0..59}
  @type datetime :: {date, time}
  @type timestamp :: {pos_integer, 0..999999, 0..999999}

  defp integer_to_abbreviated_day_of_the_week(integer) do
    %{
      1 => "Mon",
      2 => "Tue",
      3 => "Wed",
      4 => "Thu",
      5 => "Fri",
      6 => "Sat",
      7 => "Sun"
    }[integer]
  end

  defp integer_to_abbreviated_month(integer) do
    %{
       1 => "Jan",
       2 => "Feb",
       3 => "Mar",
       4 => "Apr",
       5 => "May",
       6 => "Jun",
       7 => "Jul",
       8 => "Aug",
       9 => "Sep",
      10 => "Oct",
      11 => "Nov",
      12 => "Dec"
    }[integer]
  end

  @spec datetime_to_string(datetime) :: datetime
  def datetime_to_string(datetime) do
    {{yr, mon, day}, {hr, min, sec}} = datetime

    day_of_week = {yr, mon, day}
    |> :calendar.day_of_the_week
    |> integer_to_abbreviated_day_of_the_week

    month = integer_to_abbreviated_month mon

    [day, hr, min, sec] = [day, hr, min, sec]
    |> Enum.map(&:io_lib.format("~2.10.0B", [&1]))
    |> Enum.map(&:binary.list_to_bin(&1))

    "#{day_of_week} #{month} #{day} #{hr}:#{min}:#{sec} #{yr}"
  end 
  
  @spec unix_epoch_as_datetime :: {{1970, 1, 1}, {0, 0, 0}}
  def unix_epoch_as_datetime, do: {{1970, 1, 1}, {0, 0, 0}}

  @spec unix_epoch_in_gregorian_seconds :: pos_integer
  def unix_epoch_in_gregorian_seconds do
    :calendar.datetime_to_gregorian_seconds unix_epoch_as_datetime
  end

  @spec datetime_to_epoch_time(datetime) :: pos_integer
  def datetime_to_epoch_time(datetime) do
    gregorian_seconds = :calendar.datetime_to_gregorian_seconds datetime
    
    gregorian_seconds - unix_epoch_in_gregorian_seconds
  end 

  @spec epoch_time_to_datetime(pos_integer) :: datetime
  def epoch_time_to_datetime(epoch) do
    gregorian_seconds = epoch + unix_epoch_in_gregorian_seconds

    :calendar.gregorian_seconds_to_datetime gregorian_seconds
  end

  @spec month_to_number(String.t) :: pos_integer
  def month_to_number(month) do
    %{
      "jan" => 1,  "january"   => 1,
      "feb" => 2,  "february"  => 2,
      "mar" => 3,  "march"     => 3,
      "apr" => 4,  "april"     => 4,
      "may" => 5,
      "jun" => 6,  "june"      => 6,
      "jul" => 7,  "july"      => 7,
      "aug" => 8,  "august"    => 8,
      "sep" => 9,  "september" => 9,
      "oct" => 10, "october"   => 10,
      "nov" => 11, "november"  => 11,
      "dec" => 12, "december"  => 12
    }[String.downcase(month)]
  end

  def flatten_nested_tuples(remnant) when not is_tuple(remnant), do: remnant
  def flatten_nested_tuples(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list
    |> Enum.map(&(flatten_nested_tuples &1))
    |> List.flatten
  end

  @spec is_valid_date?(pos_integer, 1..12, 1..31) :: boolean
  @spec is_valid_date?(date) :: boolean
  def is_valid_date?(y, m, d), do: is_valid_date?({y, m, d})
  def is_valid_date?(date), do: :calendar.valid_date(date)

  @spec is_valid_time?(0..23, 0..59, 0..59) :: boolean
  @spec is_valid_time?(time) :: boolean
  def is_valid_time?(h, m, s), do: is_valid_time?({h, m, s})
  def is_valid_time?({h, m, s}) when h in 0..23
                                 and m in 0..59
                                 and s in 0..59, do: true
  def is_valid_time?(_), do: false

  @spec is_valid_datetime?(datetime) :: boolean
  def is_valid_datetime?({date, time}) do
    is_valid_date?(date) && is_valid_time?(time)
  end

  @spec iso8601_to_datetime(String.t) :: datetime | {:error, atom}
  def iso8601_to_datetime(iso_string) do
    [year, month, day, hr, min, sec | _tail] = iso_string
    |> :binary.split(["-", "T", ":", "+", "Z"], [:global])
    |> Enum.map(fn "" -> ""; x -> String.to_integer x end)

    {{year, month, day}, {hr, min, sec}}
  end

  defp offset_to_iso8601(offset) do
    cond do
       offset < 0 ->
        :io_lib.format("-~4.10.0B", offset * 100)

       offset > 0 ->
        :io_lib.format("+~4.10.0B", offset * 100)

       offset == 0 ->
        "Z"
    end
  end

  @spec datetime_to_iso8601(datetime) :: String.t
  def datetime_to_iso8601(datetime, offset \\ 0) do
    fmt_args = datetime |> flatten_nested_tuples
    iso_offset = offset_to_iso8601(offset)

    "~4.10B-~2.10.0B-~2.10.0BT~2.10.0B:~2.10.0B:~2.10.0B~s"
    |> :io_lib.format(fmt_args ++ [iso_offset])
    |> List.flatten
    |> List.to_string
  end

  @spec is_iso8601?(String.t) :: boolean
  def is_iso8601?(x) when is_binary x do
    Regex.match?(~r/^\d{4}-\d{1,2}-\d{1,2}T\d{2}:\d{2}:\d{2}([+-]\d{2,4}|Z)$/, x)
  end
  def is_iso8601?(_), do: false

  @spec datetime_to_timestamp(datetime) :: timestamp
  def datetime_to_timestamp(datetime) do
    epoch_time = datetime_to_epoch_time datetime

    {div(epoch_time, 1000000), rem(epoch_time, 1000000), 0}
  end

  @spec timestamp_to_usecs(timestamp) :: pos_integer
  def timestamp_to_usecs({mega_secs, secs, usecs}) do
    secs_plus_usecs_in_usecs = [secs, usecs]
    |> Enum.map(fn x -> :io_lib.format "~6..0B", [x] end)

    [mega_secs, secs_plus_usecs_in_usecs]
    |> Enum.join
    |> String.to_integer
  end

  @spec iso8601_to_bson(String.t) :: Struct.t
  def iso8601_to_bson(iso8601) do
    iso8601
    |> iso8601_to_datetime
    |> datetime_to_timestamp
    |> Bson.UTC.from_now
  end

  @spec diff_datetime(datetime, datetime) :: pos_integer
  def diff_datetime(datetime1, datetime2) do
    greg_secs1 = :calendar.datetime_to_gregorian_seconds datetime1
    greg_secs2 = :calendar.datetime_to_gregorian_seconds datetime2

    abs(greg_secs2 - greg_secs1)
  end
end
