module Permissions
  class ContextApiClientPermission < ApplicationRecord
    belongs_to :context
    belongs_to :api_client
  end
end
