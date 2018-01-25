require './lib/json_types'

class JsonValue
  TYPES = [
    JsonNumber,
    JsonArray,
    JsonObject,
    JsonString,
    JsonBool,
    JsonNull,
  ]

  attr_accessor :type, :value

  def initialize(val)
    v = case val
    when Array
      val.map { |v_| JsonValue.new(v_) }
    when Hash
      built = {}
      val.each { |k, v| built[k] = JsonValue.new(v) }
      built
    else
      val
    end

    self.value = get_value(v)
    self.type = get_type(v)
  end

  def get_value(v)
    if v.is_a?(Hash)
      v.indifferent
    else
      v
    end
  end

  def get_type(raw_value)
    t = TYPES.find { |type| type.matches?(raw_value) }
    t || raise("no type for: #{raw_value}")
  end

  def to_json_schema
    schema = if type == JsonNull
               {}
             else
               { type: type.schema_type }
             end

    schema.merge(type.other_schema_fields(value: value)).indifferent
  end

  def schema_type
    type.schema_type
  end

  def paths(prefix)
    type.paths(value: value, prefix: prefix)
  end

  def get_swagger_lines(key: '', depth: '', references: {})
    lines = type.get_swagger_lines(key, depth, value, references)

    lines.map do |l|
      l.prepend(depth)
    end.join("\n")
  end

  def ==(other)
    self.type == other.type && self.value == other.value
  end

  def <=>(other)
    schema_value <=> other.schema_value
  end

  def collection?
    type.collection?
  end
end
