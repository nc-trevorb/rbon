require 'json'
require 'pry'

def reload
  begin
    load './lib/json_to_schema.rb'
  rescue LoadError
    # FIXME should be able to start from anywhere
    puts "couldn't find './lib/json_to_schema.rb', run bin/console from project root"
  end
end

reload

schema = JsonToSchema.aggregate_schema('AppServerForecastResponse', write: false)

binding.pry
