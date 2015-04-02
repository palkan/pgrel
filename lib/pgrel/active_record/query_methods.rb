require 'active_record/relation'

RAILS_5 = ActiveRecord.version >= Gem::Version.new("5")

module ActiveRecord
  module QueryMethods
    class StoreChain
      def initialize(scope, store_name)
        @scope = scope
        @store_name = store_name
      end

      def key(key)
        update_scope "#{@store_name} ? :key", key: key.to_s
      end

      def keys(*keys)
        update_scope "#{@store_name} ?& ARRAY[:keys]", keys: keys.map(&:to_s)
      end

      def any(*keys)
        update_scope "#{@store_name} ?| ARRAY[:keys]", keys: keys.map(&:to_s)
      end

      def contains(opts)
        update_scope "#{@store_name} @> #{type_cast(opts)}"
      end

      def contained(opts)
        update_scope "#{@store_name} <@ #{type_cast(opts)}"
      end

      def where(opts)
        opts.each do |k, v|
          update_scope "#{@store_name}->:key = :val", key: k, val: v.to_s
        end
        @scope
      end

      private

      if RAILS_5
        def update_scope(*opts)
          where_clause = @scope.send(:where_clause_factory).build(opts, {})
          @scope.where_clause += where_clause
          @scope
        end
      else
        def update_scope(*opts)
          @scope.where_values += @scope.send(:build_where, opts)
          @scope
        end
      end

      def type_cast(value)
        ActiveRecord::Base.connection.quote(value, @scope.klass.columns_hash[@store_name])
      end
    end

    class WhereChain
      def store(store_name, opts = nil)
        # TODO: validate that store is queryable
        chain = StoreChain.new(@scope, store_name.to_s)
        return chain.where(opts) unless opts.nil?
        chain
      end
    end
  end
end
