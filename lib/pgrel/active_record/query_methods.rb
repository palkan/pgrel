require 'active_record/relation'
require 'pgrel/active_record/store_chain'
require 'pgrel/active_record/store_chain/array_chain'
require 'pgrel/active_record/store_chain/hstore_chain'

module ActiveRecord
  module QueryMethods
    # Extend WhereChain with 'store' method.
    class WhereChain
      def store(store_name, *opts)
        store_name = store_name.to_s
        column = @scope.klass.columns_hash[store_name]
        if column.array?
          klass = ArrayChain
        else
          column_klass = column.type.capitalize
          klass = "ActiveRecord::QueryMethods::#{column_klass}Chain".constantize
        end
        chain = klass.new(@scope, store_name)
        return chain.where(*opts) unless opts.empty?
        chain
      end
    end
  end
end
