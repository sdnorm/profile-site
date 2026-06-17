class DateParser < ApplicationRecord
  WEEKDAYS = [ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" ]
  # WEEKDAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  def self.parse(expression, reference_time = DateTime.now)
    if expression.match?(/\b(minutes|hours|days|weeks) from now/)
      # need to account for something like this "3 days from now at noon"
      date_time = time_from_now(expression, reference_time)
      DateTime.new(
        date_time.year,
        date_time.month,
        date_time.day,
        date_time.hour,
        date_time.min,
        date_time.sec,
        date_time.zone
      )
    else
      date_part, time_part = expression.split(/ at | @ /)
      date = parse_date(date_part.strip, reference_time.to_date)
      time = parse_time(time_part ? time_part.strip : "now", reference_time)
      DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, time.zone)
    end
  end

  private

  def self.parse_date(date_expression, reference_date)
    case date_expression.downcase
    when "tomorrow"
      reference_date + 1
    when "end of the month"
      Date.new(reference_date.year, reference_date.month, -1)
    when /(\d+) weeks? from (\w+)(?:\s+(\w+))?/
      weeks = $1.to_i
      day_expression_parts = [ $2, $3 ].compact
      from_day_expression = day_expression_parts.join(" ")
      weeks_from_date(weeks, from_day_expression, reference_date)
    when /(\d+) months? from (\w+)(?:\s+(\w+))?/
      months = $1.to_i
      day_expression_parts = [ $2, $3 ].compact
      from_day_expression = day_expression_parts.join(" ")
      months_from_date(months, from_day_expression, reference_date)
    when /next (\w+)/
      weekday_to_date($1, reference_date, 1)
    when /last (\w+)/
      weekday_to_date($1, reference_date, -1)
    # Add other specific and relative date cases here
    else
      Date.parse(date_expression) rescue reference_date
    end
  end

  def self.weeks_from_date(weeks, from_day_expression, reference_date)
    from_date = calculate_from_date(from_day_expression, reference_date)
    from_date + weeks.weeks
  end

  def self.months_from_date(months, from_day_expression, reference_date)
    from_date = calculate_from_date(from_day_expression, reference_date)
    from_date + months.months
  end

  def self.calculate_from_date(from_day_expression, reference_date)
    case from_day_expression
    when "tomorrow"
      reference_date + 1
    when "today"
      reference_date
    when /^next (\w+)$/i
      weekday = $1.capitalize
      if WEEKDAYS.include?(weekday)
        days_until_next = (WEEKDAYS.index(weekday) - reference_date.wday) % 7
        days_until_next = 7 if days_until_next.zero?
        reference_date + days_until_next.days
      else
        reference_date
      end
    else
      weekday_to_date(from_day_expression.capitalize, reference_date, 0)
    end
  end

  def self.weekday_to_date(weekday, reference_date, direction)
    weekday = weekday.capitalize
    day_index = WEEKDAYS.index(weekday)
    return reference_date if day_index.nil?

    days_until = (day_index - reference_date.wday) % 7
    days_until += 7 if direction.positive? && days_until.zero?
    days_until -= 7 if direction.negative? && days_until.zero?
    reference_date + days_until.days
  end

  # could have these be settings set by the user and retrieved from the database
  def self.parse_time(time_expression, reference_time)
    # need to catch things like "Friday at 1" and make an assumption that the time is PM, etc.
    case time_expression.downcase
    when "now"
      reference_time
    when "noon"
      reference_time.change(hour: 12, min: 0)
    when "midnight"
      reference_time.change(hour: 0, min: 0)
    when /early morning/
      reference_time.change(hour: 6, min: 0)
    when /late evening/
      reference_time.change(hour: 21, min: 0)
    # Add other specific time expressions and relative times as needed
    else
      parse_explicit_time(time_expression, reference_time)
    end
  end

  def self.time_from_now(time_expression, reference_time)
    case time_expression.downcase
    when /(\d+) minutes from now/
      reference_time + $1.to_i.minutes
    when /(\d+) hours from now/
      reference_time + $1.to_i.hours
    when /(\d+) days from now/
      reference_time + $1.to_i.days
    when /(\d+) weeks from now/
      reference_time + $1.to_i.weeks
    end
  end

  def self.parse_explicit_time(time_expression, reference_time)
    parsed_time = DateTime.parse(time_expression) rescue nil
    if parsed_time
      reference_time.change(hour: parsed_time.hour, min: parsed_time.min, sec: parsed_time.sec)
    else
      reference_time
    end
  end
end
