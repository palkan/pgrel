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
    end
  end
end
