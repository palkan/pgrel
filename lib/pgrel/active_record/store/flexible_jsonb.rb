# frozen_string_literal: true

module ActiveRecord
  module Store
    class FlexibleJsonb < ActiveRecord::Store::FlexibleStore
      def delete_keys(*keys)
        keys.flatten!
        query = String.new "#{store_name} = #{store_name}"
        keys.length.times { query.concat(' - ?') }
        relation.update_all([query, *keys])
      end

      def merge(pairs)
        relation.update_all(["#{store_name} = #{store_name} || ?::jsonb", pairs.to_json])
      end

      def delete_pairs(pairs)
        keys = pairs.keys
        pairs = pairs.map { |k,v| { k => v } }
        @relation = relation.where.store(store_name, *pairs)
        delete_keys(keys)
      end
    end
  end
end
