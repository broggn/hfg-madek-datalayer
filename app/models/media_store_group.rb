class MediaStoreGroup < ApplicationRecord
  self.table_name = :media_stores_groups

  belongs_to :group
  belongs_to :media_store
end
