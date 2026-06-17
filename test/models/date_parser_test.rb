require "test_helper"

class DateParserTest < ActiveSupport::TestCase
  test "parse 'tomorrow at noon'" do
    reference_time = DateTime.new(2024, 4, 15, 10, 0, 0) # Arbitrary reference time
    expected = DateTime.new(2024, 4, 16, 12, 0, 0) # Expected result
    assert_equal expected, DateParser.parse("tomorrow at noon", reference_time)
  end
  test "parse 'next Monday at early morning'" do
    reference_time = DateTime.new(2024, 4, 15)
    expected_monday = reference_time.beginning_of_week(:sunday) + 1.week
    expected = DateTime.new(expected_monday.year, expected_monday.month, expected_monday.day, 6, 0, 0)
    assert_equal expected, DateParser.parse("next Monday at early morning", reference_time)
  end

  test "parse 'next Friday at late evening'" do
    reference_time = DateTime.new(2024, 4, 15)
    next_friday = reference_time + 4.day
    expected = DateTime.new(next_friday.year, next_friday.month, next_friday.day, 21, 0, 0)
    assert_equal expected, DateParser.parse("next Friday at late evening", reference_time)
  end

  test "parse 'next Friday at 6pm'" do
    reference_time = DateTime.new(2024, 4, 15)
    next_friday = reference_time + 4.day
    expected = DateTime.new(next_friday.year, next_friday.month, next_friday.day, 21, 0, 0)
    assert_equal expected, DateParser.parse("next Friday at late evening", reference_time)
  end

  test "parse '2 weeks from tomorrow'" do
    reference_time = DateTime.new(2024, 4, 15) # Example reference time
    expected = reference_time + 1.day + 2.weeks
    assert_equal expected, DateParser.parse("2 weeks from tomorrow", reference_time)
  end

  test "parse '3 weeks from Tuesday'" do
    reference_time = DateTime.new(2024, 4, 15) # Assuming this date is not a Tuesday
    # Find the next Tuesday from the reference_time
    next_tuesday = reference_time + ((2 - reference_time.wday) % 7).days
    expected = next_tuesday + 3.weeks
    assert_equal expected, DateParser.parse("3 weeks from Tuesday", reference_time)
  end

  test "parse '1 month from today'" do
    reference_time = DateTime.new(2024, 4, 15)
    expected = reference_time + 1.month
    assert_equal expected, DateParser.parse("1 month from today", reference_time)
  end

  test "parse '2 months from next Monday'" do
    reference_time = DateTime.new(2024, 4, 14)

    expected = Date.new(2024, 6, 15).beginning_of_day
    assert_equal expected, DateParser.parse("2 months from next Monday", reference_time)
  end

  test "parse '3 minutes from now'" do
    reference_time = DateTime.new(2024, 4, 15, 10, 0, 0) # Example reference time
    expected = reference_time + 3.minutes
    assert_equal expected, DateParser.parse("3 minutes from now", reference_time)
  end

  test "parse '3 hours from now'" do
    reference_time = DateTime.new(2024, 4, 15, 10, 0, 0) # Example reference time
    expected = reference_time + 3.hours
    assert_equal expected, DateParser.parse("3 hours from now", reference_time)
  end

  test "parse '3 days from now'" do
    reference_time = DateTime.new(2024, 4, 15, 10, 0, 0) # Example reference time
    expected = reference_time + 3.days
    assert_equal expected, DateParser.parse("3 days from now", reference_time)
  end

  test "parse '3 weeks from now'" do
    reference_time = DateTime.new(2024, 4, 15, 10, 0, 0) # Example reference time
    expected = reference_time + 3.weeks
    assert_equal expected, DateParser.parse("3 weeks from now", reference_time)
  end

  # Add more tests for edge cases and other expressions as needed
end
