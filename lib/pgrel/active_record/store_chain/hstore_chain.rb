# frozen_string_literal: true

module ActiveRecord
  module QueryMethods
    # Store chain for hstore columns.
    class HstoreChain < KeyStoreChain
      # Overlap values
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1, b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   Model.store(:store).overlap_values(1, 2).all
      #   #=>[Model(name: 'first', ...), Model(name: 'second')]
      def overlap_values(*values)
        query = String.new
        values.length.times do |n|
          query.concat("avals(#{quoted_store_name}) @> ARRAY[?]")
          query.concat(' OR ') if n < values.length - 1
        end
        update_scope(query, *values.map(&:to_s))
      end

      # Contains values
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1, b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   Model.store(:store).contains_values(1, 2).all #=> [Model(name: 'first', ...)]
      def contains_values(*values)
        update_scope("avals(#{quoted_store_name}) @> ARRAY[?]", values.map(&:to_s))
      end
    end
  end
end
