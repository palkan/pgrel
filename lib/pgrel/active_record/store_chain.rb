# frozen_string_literal: true

module ActiveRecord
  module QueryMethods
    # Base class for different store chains (hstore, jsonb, array).
    # Provides _containment_ queries methods.
    # Provides basic methods.
    class StoreChain
      attr_reader :store_name, :quoted_store_name

      def initialize(scope, store_name)
        @scope = scope
        @store_name = store_name
        @inverted = false
        @quoted_store_name = "#{@scope.klass.quoted_table_name}.#{@scope.klass.connection.quote_column_name(store_name)}"
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
        update_scope contains_clause(opts)
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
        update_scope "#{quoted_store_name} <@ #{type_cast(opts)}"
      end

      # Add negation to condition.
      #
      # Example
      #   Model.create!(name: 'first', store: {b: 2})
      #   Model.create!(name: 'second', store: {b: 1, c: 3})
      #
      #   Model.store(:store).not.contains({c: 3}).all #=> [Model(name: 'first')]
      #
      #   Model.store(:store).not(b: 2).all #=> [Model(name: 'second')]
      def not(opts = :chain)
        @inverted = true
        return where(opts) unless opts == :chain
        self
      end

      # Query by store values.
      # Supports array values.
      #
      # NOTE: This method uses "@>" (contains) operator with logic (AND/OR)
      # and not uses "->" (value-by-key). The use of "contains" operator allows us to
      # use GIN index effectively.
      #
      # Example
      #   Model.create!(name: 'first', store: {b: 1, c: 2})
      #   Model.create!(name: 'second', store: {b: 2, c: 3})
      #
      #   Model.store(:store, c: 2).all #=> [Model(name: 'first', ...)]
      #   #=> (SQL) select * from ... where store @> '"c"=>"2"'::hstore
      #
      #   Model.store(:store, b: [1, 2]).size #=> 2
      #   #=> (SQL) select * from ... where (store @> '"c"=>"1"'::hstore) or
      #                                     (store @> '"c"=>"2"'::hstore)
      def where(*opts)
        opts.map! { |opt| opt.is_a?(Hash) ? opt : [opt] }

        update_scope(
          opts.map do |opt|
            opt.map do |k, v|
              case v
              when Array
                "(#{build_or_contains(k, v)})"
              else
                contains_clause(k => v)
              end
            end.join(" and ")
          end.join(" or ")
        )
        @scope
      end

      protected

      if ActiveRecord.version.release >= Gem::Version.new("5")
        def update_scope(*opts)
          where_clause = build_where_clause(opts)
          @scope.where_clause += @inverted ? where_clause.invert : where_clause
          @scope
        end

        def type_cast(value)
          ActiveRecord::Base.connection.quote(
            @scope.klass.type_caster.type_cast_for_database(@store_name, value)
          )
        end
      else
        def update_scope(*opts)
          where_clause = @scope.send(:build_where, opts).map do |rel|
            @inverted ? invert_arel(rel) : rel
          end
          @scope.where_values += where_clause
          @scope
        end

        def type_cast(value)
          ActiveRecord::Base.connection.quote(
            value,
            @scope.klass.columns_hash[@store_name]
          )
        end

        def invert_arel(rel)
          case rel
          when Arel::Nodes::In
            Arel::Nodes::NotIn.new(rel.left, rel.right)
          when Arel::Nodes::Equality
            Arel::Nodes::NotEqual.new(rel.left, rel.right)
          when String
            Arel::Nodes::Not.new(Arel::Nodes::SqlLiteral.new(rel))
          else
            Arel::Nodes::Not.new(rel)
          end
        end
      end

      private

      def contains_clause(opts)
        "#{quoted_store_name} @> #{type_cast(opts)}"
      end

      def build_or_contains(k, vals)
        vals.map { |v| contains_clause(k => v) }.join(" or ")
      end

      def build_where_clause(opts)
        if ActiveRecord.version.release >= Gem::Version.new("6.1.0")
          @scope.send(:build_where_clause, opts)
        else
          @scope.send(:where_clause_factory).build(opts, [])
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
        update_scope "#{quoted_store_name} ? :key", key: key.to_s
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
          "#{quoted_store_name} ?& ARRAY[:keys]",
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
          "#{quoted_store_name} ?| ARRAY[:keys]",
          keys: keys.flatten.map(&:to_s)
        )
      end

      protected

      def to_sql_literal(prefix, node)
        Arel::Nodes::SqlLiteral.new(
          "#{prefix}'#{node.name}'"
        )
      end

      if ActiveRecord.version.release >= Gem::Version.new("5")
        def where_with_prefix(prefix, opts)
          where_clause = build_where_clause(opts)
          where_clause_ast = where_clause.ast

          # Converting `HomogenousIn` node to `In` type allows us to set its `left`
          # to sql literal as with other node types (`HomogenousIn` does not support this).
          if defined?(Arel::Nodes::HomogeneousIn) && where_clause_ast.is_a?(Arel::Nodes::HomogeneousIn)
            where_clause_ast = Arel::Nodes::In.new(where_clause_ast.left, where_clause_ast.right)
          end

          predicates = if where_clause_ast.is_a?(Arel::Nodes::And)
            where_clause.ast.children.map do |rel|
              rel.left = to_sql_literal(prefix, rel.left)
              rel
            end
          else
            where_clause_ast.left = to_sql_literal(prefix, where_clause_ast.left)
            [where_clause_ast]
          end

          params = if ActiveRecord.version.release >= Gem::Version.new("5.2.0")
            [predicates]
          else
            [predicates, where_clause.binds]
          end

          where_clause = ActiveRecord::Relation::WhereClause.new(*params)
          @scope.where_clause += @inverted ? where_clause.invert : where_clause
          @scope
        end
      else
        def where_with_prefix(prefix, opts)
          where_value = @scope.send(:build_where, opts).map do |rel|
            rel.left = to_sql_literal(prefix, rel.left)
            @inverted ? invert_arel(rel) : rel
          end
          @scope.where_values += where_value
          @scope
        end
      end
    end
  end
end
