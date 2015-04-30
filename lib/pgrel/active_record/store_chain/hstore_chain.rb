module ActiveRecord
  module QueryMethods
    # Store chain for hstore columns.
    class HstoreChain < KeyStoreChain
      # Query by store values.
      #
      # Supports array values.
      #
      # Example
      #   Model.create!(name: 'first', store: {b: 1, c: 2})
      #   Model.create!(name: 'second', store: {b: 2, c: 3})
      #
      #   Model.store(:store, c: 2).all #=> [Model(name: 'first', ...)]
      #   Model.store(:store, b: [1, 2]).size #=> 2
      def where(opts)
        opts = stringify(opts)
        where_with_prefix "#{@store_name}->", opts
      end

      private

      def stringify(val)
        case val
        when String
          val
        when Array
          val.map { |v| stringify(v) }
        when Hash
          Hash[val.map { |k, v| [stringify(k), stringify(v)] }]
        else
          val.to_s
        end
      end
    end
  end
end
