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

  class << self
    def build(val)
      case val
      when Array
        new(val.map(&method(:build)))
      when Hash
        built = {}
        val.each { |k, v| built[k] = build(v) }

        new(built)
      else
        new(val)
      end
    end

    def from_schema_value(v)
      type = TYPES.find { |t| t.get_schema_value(value: v) == v }
      new(type.default)
    end
  end

  def initialize(v)
    self.value = get_value(v)
    self.type = get_type(v)
  end

  # FIXME I think these were mostly hacks to make development easier
  # some tests are currently relying on this, can probably just call .value though
  def [](key)
    value[key]
  end

  def []=(key, new_value)
    value[key] = new_value
  end

  def get_value(v)
    if v.is_a?(Hash)
      v.with_indifferent_access
    else
      v
    end
  end

  def get_type(raw_value)
    t = TYPES.find { |type| type.matches?(raw_value) }
    t || raise("no type for: #{raw_value}")
  end

  def to_json_schema
    schema = {
      type: type.schema_type
    }.with_indifferent_access

    schema.merge(type.other_schema_fields(value: value))
  end

  # def raw_to_schema_value(raw_value)
  #   build(raw_value).schema_value
  # end

  def schema_value(in_array: false)
    # FIXME polymorphism
    if type == JsonArray
      schema_values = value.map(&:schema_value)
      if schema_values.any?{|sv| JsonObject.matches?(sv)} # FIXME make sure this #matches? check is correct
        schema_values
      else
        schema_values.uniq.sort
      end
    elsif type == JsonObject
      new_h = {}
      value.each do |k, v|
        new_h[k] = v.schema_value
      end
      new_h
    else
      type.get_schema_value(value: value, in_array: in_array)
    end
  end

  def get_swagger_lines(key: '', depth: '', references: {})
    lines = type.get_swagger_lines(key, depth, value, references)

    lines.map do |l|
      l.prepend(depth)
    end.join("\n")
  end

  def <=>(other)
    schema_value <=> other.schema_value
  end

  def collection?
    type.collection?
  end
end
