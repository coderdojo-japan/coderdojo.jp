module DojoHelper
  def dojo_count_label(count)
    if count == 1
      "#{count} Dojo"
    else
      "#{count} Dojos"
    end
  end

  def total_dojos_count(dojos)
    dojos.sum(&:counter)
  end
end