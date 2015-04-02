module ActiveRecord
  module QueryMethods
    # Store chain for array columns.
    class ArrayChain < StoreChain
      # Whether the array overlaps provided array.
      #
      # Example
      #   Model.create!(name: 'first', store: ['b', 'c'])
      #   Model.create!(name: 'second', store: ['a', 'b'])
      #
      #   Model.store(:store).overlap('c').all #=> [Model(name: 'first', ...)]
      #   Model.store(:store).overlap(['b']).size #=> 2
      def overlap(*vals)
        update_scope "#{@store_name} && #{type_cast(vals.flatten)}"
      end
    end
  end
end
