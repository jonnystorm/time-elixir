defmodule TimeTest do
  use ExUnit.Case, async: true

  test "provides Unix epoch as datetime" do
    assert Time.unix_epoch_as_datetime == {{1970, 1, 1}, {0, 0, 0}}
  end

  test "converts datetime to string" do
    assert Time.datetime_to_string(Time.unix_epoch_as_datetime)
      == "Thu Jan 01 00:00:00 1970"
  end

  test "converts datetime to epoch" do
    assert Time.datetime_to_epoch_time(Time.unix_epoch_as_datetime) == 0
  end

  test "converts epoch time to datetime" do
    assert Time.epoch_time_to_datetime(0) == Time.unix_epoch_as_datetime
  end

  test "flattens nested tuples (datetimes)" do
    assert Time.flatten_nested_tuples({{1, 2, 3}, {4, 5, 6}})
      == [1, 2, 3, 4, 5, 6]
  end

  test "converts ISO 8601 to datetime" do
    assert Time.iso8601_to_datetime("1970-01-01T00:00:00")
      == Time.unix_epoch_as_datetime
  end

  test "converts ISO 8601 with timezone to datetime" do
    assert Time.iso8601_to_datetime("1970-01-01T00:00:00-0600")
      == Time.unix_epoch_as_datetime
  end

  test "converts now() timestamp to usecs" do
    assert Time.timestamp_to_usecs({1000, 100000, 100000})
      == 1000100000100000
  end

  test "correctly justifies numbers when converting now() to usecs" do
    assert Time.timestamp_to_usecs({1000, 1000, 1})
      == 1000001000000001
  end

  test "converts datetime to ISO 8601 with Zulu timezone" do
    assert Time.datetime_to_iso8601(Time.unix_epoch_as_datetime)
      == "1970-01-01T00:00:00Z"
  end

  test "converts datetime to timestamp" do
    assert Time.datetime_to_timestamp(Time.unix_epoch_as_datetime)
      == {0, 0, 0}
  end

  test "calculates 0 seconds elapsed between two of the same datetime" do
    assert Time.diff_datetime(
      Time.unix_epoch_as_datetime,
      Time.unix_epoch_as_datetime
    ) == 0
  end

  test "calculates seconds elapsed between two different datetimes" do
    now = :calendar.universal_time

    assert Time.diff_datetime(Time.unix_epoch_as_datetime, now)
      == Time.datetime_to_epoch_time(now)
  end
end
