Dir[File.expand_path("./lib/**/*.rb")].each do |f|
  puts f
  require f
end

require 'active_support/core_ext/hash/indifferent_access'

module JsonToSchema
  class << self
    def write_swag(json)
    end

    def read_into_hash(filename)
      eval(File.read("./data/#{filename}"))
    end

    def read_into_schema(filename)
      json = eval(File.read("./data/#{filename}"))
      Convert.json_to_schema(json)
    end
  end
end