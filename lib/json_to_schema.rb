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
    def aggregate(dir)
      files = `ls #{dir}`.split
      raise "need some jsons" if files.empty?

      jsons = files.map do |f|
        # FIXME shouldn't need this gsub here
        eval(File.read("#{dir}/#{f}").gsub('null', 'nil'))
      end.uniq
    end

    # def aggregate_schema(type, write: false)
    # end

    def aggregate_schema(type, write: false)
      in_dir, out_dir = get_dirs(type)
      jsons = aggregate(in_dir)
      schema = Convert.jsons_to_schema(jsons)

      if write
        path = "#{out_dir}/schema-#{Time.current.strftime('%s%2N')}.json"
        File.write(path, JSON.pretty_generate(schema))
      end

      schema
    end

    def aggregate_paths(type)
      dir = in_dir(type)
      jsons = aggregate(dir)
      Convert.jsons_to_paths(jsons)
    end

    def get_dirs(type)
      # FIXME won't work for other people
      dirs = [
        "/Users/trevorb/code/json_to_schema/data/in/#{type}",
        "/Users/trevorb/code/json_to_schema/data/out/#{type}",
      ]

      dirs.each do |dir|
        Dir.mkdir(dir) unless Dir.exists?(dir)
      end
    end
  end
end