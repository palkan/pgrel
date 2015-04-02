module ActiveRecord
  module QueryMethods
    # Store chain for jsonb columns.
    class JsonbChain < KeyStoreChain
      # Query by store values.
      # Supports array values (convert to IN statement).
      #
      # Example
      #   Model.create!(name: 'first', store: {b: 1, c: 2})
      #   Model.create!(name: 'second', store: {b: 2, c: 3})
      #
      #   Model.store(:store, c: 2).all #=> [Model(name: 'first', ...)]
      #   Model.store(:store, b: [1, 2]).size #=> 2
      def where(opts)
        opts = flatten_json(opts)
        where_with_prefix "#{@store_name}->", opts
      end

      # Query by quality in path.
      #
      # Path can be set as object or as args.
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

      def flatten_json(val)
        Hash[
          val.map do |k, v|
            if v.is_a?(Array)
              [k, v.map { |i| ::ActiveSupport::JSON.encode(i) }]
            else
              [k, ::ActiveSupport::JSON.encode(v)]
            end
          end
        ]
      end

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
