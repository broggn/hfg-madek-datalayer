class MediaStoreUser < ApplicationRecord
  self.table_name = :media_stores_users

  belongs_to :user
  belongs_to :media_store
end
