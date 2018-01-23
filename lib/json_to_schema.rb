Dir[File.expand_path("./lib/**/*.rb")].each do |f|
  require f
end

# used for Hash#slice and HashWithIndifferentAccess
require 'active_support'
require 'active_support/core_ext'

class Hash
  def indifferent
    with_indifferent_access
  end
end

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