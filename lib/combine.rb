class Combine
  DEFAULT_CONFLICT_STRATEGY = :aggregate

  attr_accessor :conflict_strategy

  class << self
    def with_strategy(strategy)
      new(strategy: strategy)
    end

    def two_schemas(a, b)
      new.two_schemas(a, b)
    end

    def list_of_schemas(*schemas)
      new.list_of_schemas(*schemas)
    end
  end

  def initialize(strategy: nil)
    self.conflict_strategy = strategy || DEFAULT_CONFLICT_STRATEGY
  end

  def list_of_schemas(*schemas)
    head = schemas.first
    tail = schemas.drop(1)
    merged = deep_dup(head)

    tail.each_with_index do |schema, schema_index|
      merged = two_schemas(merged, schema, i: schema_index)
    end

    merged
  end

  def two_schemas(schema_a, schema_b, i: 0)
    # FIXME maybe shouldn't fix nils here
    if schema_a.nil?
      schema_b
    elsif schema_b.nil?
      schema_a
    else
      merged = deep_dup(schema_a)

      schema_b.each do |k, v|
        merged = add_to_schema(merged, k, v)
      end

      merged
    end
  end

  def add_to_schema(schema, k, v)
    if v == schema[k] || v.nil?
      # no changes needed
    elsif schema[k].nil?
      schema[k] = v
    else
      schema = resolve_conflict(schema, k, v)
    end

    schema
  end

  private

  def resolve_conflict(schema, k, v)
    new_schema = deep_dup(schema)

    case conflict_strategy
    when :aggregate
      case k
      when 'type'
        types = if schema[k].is_a?(Array)
                  schema[k] << v
                else
                  [schema[k], v]
                end.compact

        new_type = if types.uniq.length == 1
                     types.first
                   else
                     types.uniq.sort
                   end

        new_schema[k] = new_type
      when 'items'
        begin
          # FIXME should this be add_to_schema?
          new_schema[k] = resolve_conflict(schema[k], 'type', v['type'])
        rescue => e
          binding.pry
        end
      when 'properties'
        new_schema[k] = if compatible_properties?(schema[k], v)
                          schema[k].merge(v)
                        else
                          merge_individual_properties(schema[k], v)
                        end
      else
        raise "not sure what to do for #{k}"
      end
    when :raise_error
      raise "found a conflict: \nschema: #{schema}\nk: #{k}\nv: #{v}"
    else
      raise "invalid strategy: #{conflict_strategy}"
    end

    new_schema
  end

  def compatible_properties?(a, b)
    a.merge(b) == b.merge(a)
  end

  def merge_individual_properties(a, b)
    merged = {}

    a.each do |k, schema|
      merged[k] = two_schemas(a[k], b[k])
    end

    merged
  end

  def deep_dup(hash)
    Marshal.load(Marshal.dump(hash)) || {}
  end

end
