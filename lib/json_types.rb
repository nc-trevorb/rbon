class MustPassInRawValue < StandardError; end

class JsonType
  class << self
    def matches?(value)
      types.include?(value.class)
    end

    def collection?
      false
    end

    def other_schema_fields(value: nil)
      {}
    end
  end
end

class JsonBool < JsonType
  class << self
    def types
      [TrueClass, FalseClass]
    end

    def get_schema_value(value: nil, in_array: false)
      'boolean'
    end

    def schema_type
      'boolean'
    end

    def default
      true
    end

    # FIXME duplicated
    def get_swagger_lines(key, depth, value, references)
      [
        "#{key}:",
        "  type: boolean",
      ]
    end
  end
end

class JsonNull < JsonType
  class << self
    def matches?(value)
      value.nil? || value == 'null'
    end

    def get_schema_value(value: nil, in_array: false)
      "(null)"
    end

    def schema_type
      "(null)"
    end

    def default
      nil
    end

    # FIXME duplicated
    def get_swagger_lines(key, depth, value, references)
      [
        "#{key}:",
        "  type: null (unknown)",
      ]
    end
  end
end

class JsonNumber < JsonType
  class << self
    def types
      [Integer, Float]
    end

    def matches?(value)
      super || int_string?(value) || float_string?(value)
    end

    def get_schema_value(value: nil, in_array: false)
      "number"
    end

    def schema_type
      "number"
    end

    def get_swagger_lines(key, depth, value, references)
      [
        "#{key}:",
        "  type: number",
      ]
    end

    def default
      1
    end

    private

    def int_string?(value)
      value =~ /^\d*$/
    end

    def float_string?(value)
      value =~ /^(\d|\.)*$/ #&& value.count('.') == 1
    end
  end
end

class JsonString < JsonType
  class << self
    def types
      [String, Symbol]
    end

    def get_schema_value(value: nil, in_array: false)
      "string"
    end

    def schema_type
      "string"
    end

    def get_swagger_lines(key, depth, value, references)
      [
        "#{key}:",
        "  type: string",
      ]
    end


    def default
      'something'
    end
  end
end

class JsonArray < JsonType
  class << self
    def collection?
      true
    end

    def types
      [Array]
    end

    def schema_type
      'array'
    end

    def other_schema_fields(value: [])
      items = {}

      value.each do |v|
# fixme lookup by schema_value
      end

      { items: items }
    end

    def get_schema_value(value:, in_array: false)
      json_objects = value
      element_types = json_objects.map(&:schema_value)

      if element_types.any? { |et| JsonObject.matches?(et) }
        raise "mix of objects and primitives" unless element_types.all? { |et| JsonObject.matches?(et) }
        element_types.sort
      else
        element_types.uniq.sort
      end
    end

    def get_swagger_lines(key, depth, value, references)
      items_type_swagger = if value.any?(&:collection?)
                             value.first.get_swagger_lines(key: '', depth: depth).lines.drop(1).map(&:chomp).map{|l| l.gsub(/^  /, '')}
                           else
                             ["    type: #{value.map(&:schema_value).uniq.join(',')}"]
                           end

      [
        "#{key}:",
        "  type: array",
        "  items:",
      ] + items_type_swagger
    end

    def default
      []
    end
  end
end

class JsonObject < JsonType
  class << self
    def collection?
      true
    end

    def types
      [Hash, ActiveSupport::HashWithIndifferentAccess]
    end

    def schema_type
      'object'
    end

    def other_schema_fields(value: {})
      { properties: {} }
    end

    def get_schema_value(value:, in_array: false)
      if matches?(value)
        Convert.json_to_json_ruby(value).schema_value
      else
        raise "value needs to be a hash, got #{value.class}"
      end
    end

    def get_swagger_lines(key, depth, value, references)
      object_lines = [
        "#{key}:",
        "  type: object",
        "  properties:",
      ]

      plines = value.map do |k, jv|
        jv.get_swagger_lines(key: k, depth: '    ', references: references).split("\n")
      end.flatten

      object_lines + plines
    end

    def default
      {}
    end
  end
end
