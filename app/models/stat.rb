class Stat
  def initialize(period)
    @period = period
  end

  def annual_sum_total_of_aggregatable_dojo
    return @annual_sum_total_of_aggregatable_dojo if defined?(@annual_sum_total_of_aggregatable_dojo)

    hash = Dojo.aggregatable_annual_count(@period)
    @annual_sum_total_of_aggregatable_dojo = year_hash_template.merge!(hash).each.with_object({}) {|(k, v), h| h[k] = (h.values.last || 0) + v }
  end

  def annual_count_of_event_histories
    return @annual_count_of_event_histories if defined?(@annual_count_of_event_histories)

    hash = EventHistory.annual_count(@period)
    @annual_count_of_event_histories = year_hash_template.merge!(hash)
  end

  def annual_sum_of_participants
    return @annual_sum_of_participants if defined?(@annual_sum_of_participants)

    hash = EventHistory.annual_sum_of_participants(@period)
    @annual_sum_of_participants = year_hash_template.merge!(hash)
  end

  def annual_dojos_chart
    # MEMO: トップページの道場数と一致するように Active Dojo を集計対象としている
    HighChartsBuilder.build_annual_dojos(Dojo.active.annual_count(@period))
  end

  def annual_event_histories_chart
    HighChartsBuilder.build_annual_event_histories(annual_count_of_event_histories)
  end

  def annual_participants_chart
    HighChartsBuilder.build_annual_participants(annual_sum_of_participants)
  end

  private

  def year_hash_template
    initialized_year_hash.dup
  end

  def initialized_year_hash
    return @initialized_year_hash if defined?(@initialized_year_hash)
    @initialized_year_hash = years_from(@period).each.with_object({}) {|t, h| h[t.year.to_s] = 0 }
  end

  def years_from(period)
    DateTimeUtil.every_year_array(period.first, period.last)
  end
end
