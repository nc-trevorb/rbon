class RbonValue
  attr_accessor :value

  class << self
    def create(raw_value)
      types = self.descendants.select { |d| d.descendants.empty? }
      t = types.find { |type| type.matches?(raw_value) }
      t || raise("no type for: #{raw_value}")

      t.new(raw_value)
    end

    def matches?(value)
      ruby_classes.include?(value.class)
    end

    # FIXME doesn't really belong here, but I didn't want to make Utils for just one fn ¯\_(ツ)_/¯
    def prepend_path(prefix, str)
      if prefix == ''
        str
      else
        "#{prefix}/#{str}"
      end
    end
  end

  def to_json_schema
    { type: self.class.schema_type }.merge(other_schema_fields).indifferent
  end

  def schema_type
    self.class.schema_type
  end
end

class RbonCollection < RbonValue
  def collection?
    true
  end
end

class RbonPrimitive < RbonValue
  class << self
    def to_json_schema
      { type: schema_type }.indifferent
    end
  end

  def initialize(v)
    self.value = v
  end

  def collection?
    false
  end

  def other_schema_fields
    {}.indifferent
  end

  def paths(prefix:)
    ["#{prefix}:#{self.class.schema_type}"]
  end

  # for these methods, collection types need the .value but primitives don't, so we define an
  # instance method that delegates to the class method
  def default
    self.class.default
  end

  def to_json_schema
    self.class.to_json_schema
  end
end

class RbonBool < RbonPrimitive
  class << self
    def ruby_classes
      [TrueClass, FalseClass]
    end

    def schema_type
      'boolean'
    end

    def default
      true
    end
  end
end

class RbonNull < RbonPrimitive
  class << self
    def ruby_classes
      [NilClass]
    end

    def schema_type
      raise StandardError.new("json-schema for a null value should be an empty object")
    end

    def to_json_schema
      {}
    end

    def default
      nil
    end
  end
end

class RbonNumber < RbonPrimitive
  class << self
    def ruby_classes
      [Integer, Float]
    end

    def matches?(value)
      is_int_string = value =~ /^\d*$/
      is_float_string = value =~ /^(\d|\.)*$/

      super || is_int_string || is_float_string
    end

    def schema_type
      "number"
    end

    def default
      1
    end
  end
end

class RbonString < RbonPrimitive
  class << self
    def ruby_classes
      [String, Symbol]
    end

    def schema_type
      "string"
    end

    def default
      'something'
    end
  end
end

class RbonArray < RbonCollection
  class << self
    def ruby_classes
      [Array]
    end

    def schema_type
      'array'
    end
  end

  def initialize(raw_value)
    val = raw_value.map { |v| RbonValue.create(v) }
    self.value = val
  end

  def other_schema_fields
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

  def paths(prefix: '')
    value.map { |v| v.paths(prefix: "#{prefix}[]") }.uniq.flatten
  end

  def default
    value.map(&:default)
  end
end

class RbonObject < RbonCollection
  class << self
    def ruby_classes
      [Hash, ActiveSupport::HashWithIndifferentAccess]
    end

    def schema_type
      'object'
    end
  end

  def initialize(raw_value)
    val = {}
    raw_value.each { |k, v| val[k] = RbonValue.create(v) }

    self.value = val.indifferent
  end

  def other_schema_fields
    properties_types = {}

    value.each do |k, v|
      properties_types[k] = v.to_json_schema
    end

    { properties: properties_types }.indifferent
  end

  def paths(prefix: '')
    value.map do |key, json_value|
      json_value.paths(prefix: self.class.prepend_path(prefix, key))
    end.flatten
  end

  def default
    default_hash = {}

    value.each do |k, v|
      default_hash[k] = v.default
    end

    default_hash.indifferent
  end
end
