class Compare
  class << self
    def json_differences(p1, p2)
      diff = {
        missing: [],
        extra: [],
        different_types: {},
        same: p1 & p2,
      }

      remaining_p1 = p1 - p2
      p1_keys = remaining_p1.map{|p| p.split(':').first}

      (p1 - p2).each do |path|
        key, value = path.split(':')
        path_with_same_key = p2.find { |p| p.start_with?("#{key}:") }
        value_with_same_key = try_value(path_with_same_key, ':')

        if value == RbonNull.schema_type && path_with_same_key
          diff[:same] << path_with_same_key
        else
          if path_with_same_key
            if p2.include?(path)
            # noop, already included in :same
            else
              types = [path, path_with_same_key].map{|p| p.split(':').last}
              diff[:different_types][key] = types.sort
            end
          else
            diff[:extra] << path
          end
        end
      end

      p2.each do |path|
        key = path.split(':').first
        next if p1_keys.include?(key)

        diff[:missing] << path
      end

      diff
    end

    def diff_jsons(j1, j2)
      paths1 = Convert.json_to_paths(j1)
      paths2 = Convert.json_to_paths(j2)

      json_differences(paths1, paths2).indifferent
    end

    private

    def try_value(str, sep)
      if str
        str.split(sep).last
      end
    end
  end
end