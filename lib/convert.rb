class Convert
  class << self
    def get_json(input_json)
      json = input_json.with_indifferent_access

      json.each do |k, h|
        hash_with_integer_keys = JsonObject.matches?(h) && (h.keys.select {|k| k.to_i > 1}.count > 1)

        if hash_with_integer_keys
          json[k] = { '<id>' => h.values.first }
        end
      end

      json
    end

    def json_to_schema(input_json)
      if input_json.is_a?(Hash)
        json = get_json(input_json)
        json_ruby = json_to_json_ruby(json)

        json_ruby_to_json_schema(json_ruby)
      else
        JsonValue.new(input_json).to_json_schema
      end
    end

    def json_to_paths(input_json, prefix: '')
      json = get_json(input_json)
      json_ruby = json_to_json_ruby(json)

      json_ruby_to_paths(json_ruby, prefix: prefix)
    end

    def json_to_csv(input_json)
      paths_to_csv(json_to_paths(input_json))
    end

    def paths_to_org_table(paths)
      paths.map{|p| "|#{p.gsub(':', '|')}||"}.join("\n")
    end

    def json_to_json_ruby(input_json)
      raise "need to pass in hash" unless JsonObject.matches?(input_json)
      json = get_json(input_json)

      JsonValue.new(json)
    end

    def json_ruby_to_paths(json_ruby, prefix: '')
      raise "need to pass in JsonObject" unless json_ruby.type == JsonObject
      paths = []

      json_ruby.value.each do |key, json_value|
        paths += json_value.paths(JsonType.prepend_path(prefix, key))
      end

      paths
    end

    def json_ruby_to_json_schema(json_ruby)
      raise "need to pass in JsonObject" unless json_ruby.type == JsonObject
      schema = { type: JsonObject.schema_type, properties: {} }

      json_ruby.value.each do |k, v|
        schema[:properties][k] = if v.type == JsonObject
                                   json_ruby_to_json_schema(v)
                                 elsif v.type == JsonArray
                                   schemas = if v.value.any? { |v_| v_.type == JsonObject }
                                               v.value.map(&method(:json_ruby_to_json_schema))
                                             else
                                               v.value.map(&:to_json_schema)
                                             end.uniq

                                   items_value = if schemas.length == 1
                                                   schemas.first
                                                 else
                                                   Combine.list_of_schemas(*schemas.uniq)
                                                 end


                                   { type: 'array', items: items_value }
                                 else
                                   v.to_json_schema
                                 end
      end

      schema.indifferent
    end
  end
end
