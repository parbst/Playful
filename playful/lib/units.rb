module Units
  def self.get_in_kilobytes_pr_sec(input)
    unit_calculation(input, {
      :'mb/s' => 1000,
      :'kb/s' => 1,
      :'b/s'  => 0.001
    })
  end

  def self.get_in_hz(input)
    unit_calculation(input, {
      :'mhz'  => 1000000,
      :'khz' => 1000,
      :'hz' => 1
    })
  end

  def self.unit_calculation(val_unit_string, unit_to_factor)
    if val_unit_string =~ /(\d+([\.\,]\d+)?)\s*(.+)/
      value = $1.to_f
      unit = $3
      key = unit.gsub(/\s/, '').downcase.to_sym
      factor = unit_to_factor.has_key?(key) ? unit_to_factor[key] : 1
      value * factor
    end
  end
end
