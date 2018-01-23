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

json = JsonToSchema.read_into_hash('appserver_response')
schema = Convert.json_to_schema(json)

binding.pry
