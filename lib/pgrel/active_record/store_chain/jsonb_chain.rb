# frozen_string_literal: true

module ActiveRecord
  module QueryMethods
    # Store chain for jsonb columns.
    class JsonbChain < KeyStoreChain
      OPERATORS = {contains: "@>", overlap: "&&"}.freeze

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

        path = "{#{args.join(",")}}"

        case val
        when Hash
          op = "#>"
          val = ::ActiveSupport::JSON.encode(val)
        when Array
          op = "#>>"
          val = val.map(&:to_s)
        else
          op = "#>>"
          val = val.to_s
        end

        where_with_prefix "#{quoted_store_name}#{op}", path => val
      end

      # Overlap values
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1, b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   Model.store(:store).overlap_values(1, 2).all
      #   #=>[Model(name: 'first', ...), Model(name: 'second')]
      def overlap_values(*values)
        update_scope(value_query(:overlap), cast_values(values))
      end

      # Contains values
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1, b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   Model.store(:store).contains_values(1, 2).all #=> [Model(name: 'first', ...)]
      def contains_values(*values)
        update_scope(value_query(:contains), cast_values(values))
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

      def value_query(operator)
        oper = OPERATORS[operator]
        "(SELECT array_agg(value) FROM jsonb_each(#{quoted_store_name})) #{oper} ARRAY[?]::jsonb[]"
      end

      def cast_values(values)
        values.map do |v|
          case v
          when Hash, Array, String
            v.to_json
          else
            v.to_s
          end
        end
      end
    end
  end
end
