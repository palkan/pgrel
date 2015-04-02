module ActiveRecord
  module QueryMethods
    # Hstore chain for hstore columns.
    # Handle conversion of all values to string.
    class HstoreChain < StoreChain
      def initialize(scope, store_name)
        @scope = scope
        @store_name = store_name
      end

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
      if RAILS_5
        def where(opts)
          opts = stringify(opts)
          where_clause = @scope.send(:where_clause_factory).build(opts, {})
          predicates = where_clause.ast.children.map do |rel|
            rel.left = to_sql_literal("#{@store_name}->", rel.left)
            rel
          end
          where_clause = ActiveRecord::Relation::WhereClause.new(predicates, where_clause.binds)
          @scope.where_clause += where_clause
          @scope
        end
      else
        def where(opts)
          opts = stringify(opts)
          where_value = @scope.send(:build_where, opts).map do |rel|
            rel.left = to_sql_literal("#{@store_name}->", rel.left)
            rel
          end
          @scope.where_values += where_value
          @scope
        end
      end

      private

      def stringify(val)
        case val
        when String
          val
        when Array
          val.map { |v| stringify(v) }
        when Hash
          Hash[val.map { |k, v| [k, stringify(v)] }]
        else
          val.to_s
        end
      end
    end
  end
end
