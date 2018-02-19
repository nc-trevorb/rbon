class Convert
  class << self

    def json_to_rbon(input_json)
      json = format_input(input_json)

      RbonValue.create(json)
    end

    def json_to_schema(input_json)
      if input_json.is_a?(Hash)
        json = format_input(input_json)
        rbon = json_to_rbon(json)

        rbon.to_json_schema
      else
        RbonValue.create(input_json).to_json_schema
      end
    end

    # FIXME looks like I don't need this prefix arg
    def json_to_paths(input_json, prefix: '')
      json = format_input(input_json)
      rbon = json_to_rbon(json)

      rbon_to_paths(rbon, prefix: prefix)
    end

    def rbon_to_paths(rbon, prefix: '')
      raise "need to pass in RbonObject" unless rbon.class == RbonObject
      paths = []

      rbon.value.each do |key, json_value|
        paths += json_value.paths(prefix: RbonValue.prepend_path(prefix, key))
      end

      paths
    end

    private

    def format_input(input, integer_key: 'id') # e.g. 'age' for allocations, 'percentile' for percentile data, etc.
      return input unless input.is_a?(Hash)

      json = input.indifferent

      json.each do |k, h|
        hash_with_integer_keys = RbonObject.matches?(h) && (h.keys.select {|k| k.to_i > 1}.count > 1)

        if hash_with_integer_keys
          # FIXME shouldn't have this here
          json[k] = { "<#{integer_key}>" => h.values.first }
        end
      end

      json
    end

  end
end
