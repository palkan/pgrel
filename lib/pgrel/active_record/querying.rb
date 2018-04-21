module ActiveRecord
  module Querying
    delegate :update_store, to: :all
  end
end
