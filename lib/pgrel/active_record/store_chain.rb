# Check rails version
RAILS_5 = ActiveRecord.version.release >= Gem::Version.new("5")

module ActiveRecord
  module QueryMethods
    # Base class for different store chains (hstore, jsonb, array).
    # Provides _containment_ queries methods.
    # Provides basic methods.
    class StoreChain
      def initialize(scope, store_name)
        @scope = scope
        @store_name = store_name
      end

      # Whether the store contains provided store
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1, b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   data = {a: 1}
      #   Model.store(:store).contains(data).all #=> [Model(name: 'first', ...)]
      def contains(opts)
        update_scope "#{@store_name} @> #{type_cast(opts)}"
      end

      # Whether the store is contained within provided store
      #
      # Example
      #   Model.create!(name: 'first', store: {b: 1})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   data = {b: 1, c: 2}
      #   Model.store(:store).contains(data).all #=> [Model(name: 'first', ...)]
      def contained(opts)
        update_scope "#{@store_name} <@ #{type_cast(opts)}"
      end

      if RAILS_5
        protected

        def update_scope(*opts)
          where_clause = @scope.send(:where_clause_factory).build(opts, {})
          @scope.where_clause += where_clause
          @scope
        end

        def type_cast(value)
          ActiveRecord::Base.connection.quote(
            @scope.table.type_cast_for_database(@store_name, value)
          )
        end

        def where_with_prefix(prefix, opts)
          where_clause = @scope.send(:where_clause_factory).build(opts, {})
          predicates = where_clause.ast.children.map do |rel|
            rel.left = to_sql_literal(prefix, rel.left)
            rel
          end
          where_clause = ActiveRecord::Relation::WhereClause.new(
            predicates,
            where_clause.binds
          )
          @scope.where_clause += where_clause
          @scope
        end
      else
        protected

        def update_scope(*opts)
          @scope.where_values += @scope.send(:build_where, opts)
          @scope
        end

        def type_cast(value)
          ActiveRecord::Base.connection.quote(
            value,
            @scope.klass.columns_hash[@store_name]
          )
        end

        def where_with_prefix(prefix, opts)
          where_value = @scope.send(:build_where, opts).map do |rel|
            rel.left = to_sql_literal(prefix, rel.left)
            rel
          end
          @scope.where_values += where_value
          @scope
        end
      end
    end

    # Base class for key-value types of stores (hstore, jsonb)
    class KeyStoreChain < StoreChain
      # Single key existence
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1})
      #   Model.create!(name: 'second', store: {b: 1})
      #
      #   # Get all records which have key 'a' in store 'store'
      #   Model.store(:store).key('a').all #=> [Model(name: 'first', ...)]
      def key(key)
        update_scope "#{@store_name} ? :key", key: key.to_s
      end

      # Several keys existence
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1, b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   Model.store(:store).keys('a','b').all #=> [Model(name: 'first', ...)]
      def keys(*keys)
        update_scope(
          "#{@store_name} ?& ARRAY[:keys]",
          keys: keys.flatten.map(&:to_s)
        )
      end

      # Any of the keys existence
      #
      # Example
      #   Model.create!(name: 'first', store: {a: 1, b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   Model.store(:store).keys('a','b').count #=> 2
      def any(*keys)
        update_scope(
          "#{@store_name} ?| ARRAY[:keys]",
          keys: keys.flatten.map(&:to_s)
        )
      end

      protected

      def to_sql_literal(prefix, node)
        Arel::Nodes::SqlLiteral.new(
          "#{prefix}'#{node.name}'"
        )
      end
    end
  end
end
