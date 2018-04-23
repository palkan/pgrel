# frozen_string_literal: true

module ActiveRecord
  module Store
    class FlexibleStore
      attr_reader :relation, :store_name

      def initialize(relation, store_name)
        @relation, @store_name = relation, store_name
      end
    end
  end
end
