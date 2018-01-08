class Combine
  class << self
    def deep_dup(hash)
      Marshal.load(Marshal.dump(hash))
    end

    def merge_schemas(*schemas)
      merged = deep_dup(schemas.flatten.first)

      schemas.drop(1).each_with_index do |schema, schema_index|
        merged = merge_two_schemas(merged, schema, i: schema_index)
      end

      merged
    end

    def merge_two_schemas(schema_a, schema_b, i: 0)
      merged = deep_dup(schema_a)

      schema_b.each do |k, v|
        conflicts = false
        value = if [nil, v, '(null)'].include?(merged[k])
                  v
                elsif v == '(null)'
                  merged[k]
                else
                  # FIXME this is weird, no reason to assign this assignment to `value`
                  conflicts = true
                end

        if conflicts
          old = merged[k]
          orig = merged.delete(k)
          merged["#{k}_conflict_#{i}".to_sym] = orig
          merged["#{k}_conflict_#{i+1}".to_sym] = v
        else
          merged[k] = value
        end
      end

      merged
    end
  end
end