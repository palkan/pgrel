# frozen_string_literal: true

module ActiveRecord
  module QueryMethods
    # Store chain for hstore columns.
    class HstoreChain < KeyStoreChain
    end
  end
end
