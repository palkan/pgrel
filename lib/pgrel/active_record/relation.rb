# frozen_string_literal: true

module ActiveRecord
  class Relation
    def update_store(store_name)
      raise ArgumentError, "Empty store name to update" if store_name.blank?
      type = type_for_attribute(store_name.to_s).type
      raise TypeConflictError, "Column type mismatch" if %i(hstore jsonb).exclude?(type)
      klass = "ActiveRecord::Store::Flexible#{type.capitalize}".constantize
      klass.new(self, store_name)
    end
  end
end
