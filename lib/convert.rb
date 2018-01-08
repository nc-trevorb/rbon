class Convert
  class << self
    def get_json(input_json)
      json = input_json.with_indifferent_access

      json.each do |k, h|
        hash_with_integer_keys = JsonObject.matches?(h) && (h.keys.select {|k| k.to_i > 1}.count > 1)

        if hash_with_integer_keys
          # FIXME conflict resolution strategy
          json[k] = { '<id>' => h.values.first }
        end
      end

      json
    end

    def json_to_swag(input_json, name)
      json = get_json(input_json)
      json_to_json_ruby(json).get_swagger_lines(key: name)
    end

    def json_to_schema(input_json)
      json = get_json(input_json)
      json_ruby = json_to_json_ruby(json)

      json_ruby_to_json_schema(json_ruby)
    end

    def json_to_paths(input_json)
      json = get_json(input_json)
      json_ruby = json_to_json_ruby(json)
      json_schema = json_ruby_to_json_schema(json_ruby)

      json_schema_to_json_paths(json_schema)
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

      JsonValue.build(json)
    end

    def json_ruby_to_json_schema(json_ruby, in_array: false)
      raise "need to pass in JsonObject" unless json_ruby.type == JsonObject
      schema = {}

      json_ruby.value.each do |k, v|
        schema[k] = if v.type == JsonObject
                      json_ruby_to_json_schema(v)
                    elsif v.type == JsonArray
                      if v.value.any? { |v_| v_.type == JsonObject }
                        schemas = v.value.map(&method(:json_ruby_to_json_schema))

                        if schemas.uniq.length == 1
                          schemas
                        else
                          Combine.merge_schemas(*schemas.uniq)
                        end
                      else
                        v.value.map(&:schema_value).uniq.sort
                      end
                    else
                      v.schema_value(in_array: in_array)
                    end
      end

      schema.with_indifferent_access
    end

    def json_schema_to_json_paths(schema, prefix='')
      schema.map do |key, type|
        type_to_path(key, type, prefix)
      end.flatten
    end

    def json_schema_to_json_ruby(json_schema)
      json_ruby = {}

      json_schema.each do |k, v|
        json_ruby[k] = JsonValue.from_schema_value(v)
      end

      json_ruby.with_indifferent_access
    end

    def prepend_path(prefix, str)
      if prefix == ''
        str
      else
        "#{prefix}.#{str}"
      end
    end

    def type_to_path(key, type, prefix)
      if JsonObject.matches?(type)
        json_schema_to_json_paths(type, prepend_path(prefix, key))
      elsif type.is_a?(Array)
        get_array_paths(key, type, prefix).flatten
      else
        if type.include?(':') && !type.include?('{')
          type.split(',').map do |t|
            prepend_path(prefix, "#{key}.#{t}")
          end.join(',')
        else
          prepend_path(prefix, "#{key}:#{type}")
        end
      end
    end

    private

    def get_array_paths(key, type, prefix)
      if type.any?{|el| JsonObject.matches?(el) }
        types = type.uniq.map.with_index do |el, i|
          json_schema_to_json_paths(el).map do |path|
            if path.count(':') > 1
              raise 'there was a problem (might be parsing nested hashes?)'
            else
              prepend_path(prefix, "#{key}<#{i}>.#{path}")
            end
          end
        end

        if types.length == 1
          if type.length == 1
            types.flatten.map{|t| t.gsub('<0>', '<>')}
          else
            types.flatten.map{|t| t.gsub('<0>', '<all>')}
          end
        else
          types
        end
      else
        [prepend_path(prefix, "#{key}<>:#{type.join(',')}")]
      end
    end
  end
end
