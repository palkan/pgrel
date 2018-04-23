# frozen_string_literal: true

module ActiveRecord
  module Store
    class FlexibleHstore < ActiveRecord::Store::FlexibleStore
      def delete_keys(*keys)
        keys = keys.flatten.map(&:to_s)
        relation.update_all(["#{store_name} = delete(#{store_name}, ARRAY[:keys])", keys: keys])
      end

      def merge(pairs)
        relation.update_all(["#{store_name} = hstore(#{store_name}) || hstore(ARRAY[:keys])",
                            keys: pairs.to_a.flatten.map(&:to_s)])
      end

      def delete_pairs(pairs)
        relation.update_all(
          ["#{store_name} = delete(#{store_name}, hstore(ARRAY[:keys], ARRAY[:values]))",
           keys: pairs.keys.map(&:to_s), values: pairs.values.map(&:to_s)]
        )
      end
    end
  end
end
