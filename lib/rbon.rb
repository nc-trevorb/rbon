Dir[File.expand_path("./lib/**/*.rb")].each do |f|
  require f unless f.end_with?("/rbon.rb")
end

require 'json'
require 'json-schema'
require 'pry'

# used for Hash#slice and HashWithIndifferentAccess
require 'active_support'
require 'active_support/core_ext'

class Hash
  def indifferent
    with_indifferent_access
  end
end

module Rbon
  AGGREGATION_IN_DIR = "./data/aggregation/in"
  AGGREGATION_OUT_DIR = "./data/aggregation/out"
  VALIDATION_SCHEMA_PATH = "./data/validation/schema.json"
  VALIDATION_INPUT_PATH = "./data/validation/input.json"

  class << self

    def aggregate(name, write: false, overwrite: false)
      in_dir, out_dir = create_dirs(name)
      jsons = get_jsons_from_dir(in_dir)

      schemas = jsons.map { |json| Convert.json_to_schema(json) }
      schema = Combine.list_of_schemas(*schemas)

      if write
        timestamp = Time.current.strftime('%s%2N')
        path = "#{out_dir}/schema-#{timestamp}.json"

        File.write(path, JSON.pretty_generate(schema))
      end

      schema
    end

    def run_validation
      schema = eval(File.read(VALIDATION_SCHEMA_PATH))
      input = eval(File.read(VALIDATION_INPUT_PATH))

      begin
        JSON::Validator.validate!(schema, input)
        puts 'OK'
      rescue => e
        puts e
      end
    end

    def log_json(json, path: "./log/rbon/jsons")
      FileUtils.mkdir_p(path)
      File.write(path, JSON.pretty_generate(json))
    end

    private

    def get_jsons_from_dir(dir)
      file_paths = Dir["#{dir}/*"]
      raise "need some jsons in #{dir}" if file_paths.empty?

      file_paths.map do |fp|
        eval(File.read(fp))
      end.uniq
    end

    def create_dirs(name)
      dirs = [
        "#{AGGREGATION_IN_DIR}/#{name}",
        "#{AGGREGATION_OUT_DIR}/#{name}",
      ]

      dirs.each do |dir|
        Dir.mkdir(dir) unless Dir.exists?(dir)
      end

      dirs
    end
  end
end