module DateTimeUtil
  class << self
    def every_year_array(from, to)
      loop.with_object([from]) do |_, array|
        target = array.last.next_year
        raise StopIteration if target > to
        array << target
      end
    end

    def every_month_array(from, to)
      loop.with_object([from]) do |_, array|
        target = array.last.next_month
        raise StopIteration if target > to
        array << target
      end
    end

    def every_week_array(from, to)
      wday = from.strftime('%A').downcase.to_sym
      loop.with_object([from]) do |_, array|
        target = array.last.next_week(wday)
        raise StopIteration if target > to
        array << target
      end
    end

    def every_day_array(from, to)
      loop.with_object([from]) do |_, array|
        target = array.last.next_day
        raise StopIteration if target > to
        array << target
      end
    end
  end
end
