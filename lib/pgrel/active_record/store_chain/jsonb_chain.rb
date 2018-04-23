# frozen_string_literal: true

module ActiveRecord
  module QueryMethods
    # Store chain for jsonb columns.
    class JsonbChain < KeyStoreChain
      # Query by value in path.
      #
      # Example:
      #   Model.create!(name: 'first', store: {b: 1, c: { d: 3 } })
      #   Model.create!(name: 'second', store: {b: 2, c: { d: 1 }})
      #
      #   Model.store(:store).path(c: {d: 3}).all #=> [Model(name: 'first', ...)]
      #   Model.store(:store).path('c', 'd', [1, 3]).size #=> 2
      def path(*args)
        args = flatten_hash(args.first) if args.size == 1
        val = args.pop

        path = "{#{args.join(',')}}"

        case val
        when Hash
          op = '#>'
          val = ::ActiveSupport::JSON.encode(val)
        when Array
          op = '#>>'
          val = val.map(&:to_s)
        else
          op = '#>>'
          val = val.to_s
        end

        where_with_prefix "#{@store_name}#{op}", path => val
      end

      # Value existence
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1, b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   Model.store(:store).values(1, 2).all
      #   #=>[Model(name: 'first', ...), Model(name: 'second')]
      def value(*values)
        query = String.new
        values = values.map do |v|
          case v
          when Hash, Array, String
            v.to_json
          else
            v.to_s
          end
        end

        values.length.times do |n|
          query.concat(value_existence_query)
          query.concat(' OR ') if n < values.length - 1
        end
        update_scope(query, *values)
      end

      # Values existence
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1, b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   Model.store(:store).values(1, 2).all #=> [Model(name: 'first', ...)]
      def values(*values)
        values = values.map do |v|
          case v
          when Hash, Array, String
            v.to_json
          else
            v.to_s
          end
        end
        update_scope(value_existence_query, values)
      end

      private

      def flatten_hash(hash)
        case hash
        when Hash
          hash.flat_map { |k, v| [k, *flatten_hash(v)] }
        when Array
          [hash]
        else
          hash
        end
      end

      def value_existence_query
        "(SELECT array_agg(value) FROM jsonb_each(#{@store_name})) @> ARRAY[?]::jsonb[]"
      end
    end
  end
end
