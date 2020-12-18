# frozen_string_literal: true

module ActiveRecord
  module Querying
    delegate :update_store, to: :all
  end
end
