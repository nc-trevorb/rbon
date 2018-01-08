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

ui = JsonToSchema.read_into_hash('appserver_response')
response = JsonToSchema.read_into_hash('advice_map_responses')
request = JsonToSchema.read_into_hash('advice_map_requests')

ui_swag = Convert.json_to_swag(ui, 'ui')
request_swag = Convert.json_to_swag(request, 'request')
response_swag = Convert.json_to_swag(response, 'response')

binding.pry
