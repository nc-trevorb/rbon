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
      {}.indifferent
    end

    def paths(prefix: '', value: nil)
      ["#{prefix}:#{schema_type}"]
    end

    def prepend_path(prefix, str)
      if prefix == ''
        str
      else
        "#{prefix}/#{str}"
      end
    end
  end
end

class JsonBool < JsonType
  class << self
    def types
      [TrueClass, FalseClass]
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

    def schema_type
      ''
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

    def other_schema_fields(value: nil)
      schemas = value.map(&:to_json_schema).uniq

      items_value = if schemas.length == 1
                      schemas.first
                    else
                      Combine.list_of_schemas(*schemas.uniq)
                    end

      { items: items_value }.indifferent
    end

    def all_simple_schemas?(schemas)
      schemas.all? { |schema| schema.keys == ['type'] }
    end

    def paths(prefix: '', value: [])
      value.map { |v| v.paths("#{prefix}[]") }.uniq.flatten
    end

    def get_swagger_lines(key, depth, value, references)
      items_type_swagger = if value.any?(&:collection?)
                             value.first.get_swagger_lines(key: '', depth: depth).lines.drop(1).map(&:chomp).map{|l| l.gsub(/^  /, '')}
                           else
                             ["    type: #{value.map(&:schema_type).uniq.join(',')}"]
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
      properties_types = {}

      value.each do |k, v|
        properties_types[k] = v.to_json_schema
      end

      { properties: properties_types }.indifferent
    end

    def paths(prefix: '', value: {})
      value.map do |key, json_value|
        json_value.paths(prepend_path(prefix, key))
      end.flatten
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
