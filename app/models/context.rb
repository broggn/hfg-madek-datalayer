class Context < ApplicationRecord
  include Concerns::Contexts::AccessScopes
  include Concerns::LocalizedFields

  has_many(:context_keys,
           -> { order('context_keys.position ASC') },
           foreign_key: :context_id, dependent: :destroy)
  has_many :api_client_permissions, class_name: 'Permissions::ContextApiClientPermission'

  localize_fields :labels, :descriptions

  def to_s
    id
  end

end
