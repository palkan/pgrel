# frozen_string_literal: true

module ActiveRecord
  module QueryMethods
    # Store chain for hstore columns.
    class HstoreChain < KeyStoreChain
      # Value existence
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1, b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   Model.store(:store).value(1, 2).all
      #   #=>[Model(name: 'first', ...), Model(name: 'second')]
      def value(*values)
        query = String.new
        values.length.times do |n|
          query.concat("avals(#{@store_name}) @> ARRAY[?]")
          query.concat(' OR ') if n < values.length - 1
        end
        update_scope(query, *values.map(&:to_s))
      end

      # Values existence
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1, b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   Model.store(:store).values(1, 2).all #=> [Model(name: 'first', ...)]
      def values(*values)
        update_scope("avals(#{@store_name}) @> ARRAY[?]", values.map(&:to_s))
      end
    end
  end
end
