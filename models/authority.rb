# At this point, you can access the ActiveRecord::Base class using the
# "database" object:
#puts "the authorities table doesn't exist" if !database.table_exists?('authorities')

class Authority < ActiveRecord::Base
  def self.find_by_location(location)
    geo2gov_response = Geo2gov.new(location)
    lga_code = geo2gov_response.lga_code[3..-1] if geo2gov_response.lga_code
    find_by_lga_code(lga_code.to_i) if lga_code
  end
end
