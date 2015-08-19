defmodule TimeTest do
  use ExUnit.Case, async: true

  test "converts datetime to string" do
    assert Time.datetime_to_string({{1970, 1, 1}, {0, 0, 0}})
    == "Thu Jan 01 00:00:00 1970"
  end
end
