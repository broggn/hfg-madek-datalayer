class MediaStore < ApplicationRecord
  self.inheritance_column = :_not_relevant

  TYPES = %w(
    database
    filesystem
    S3).freeze

  has_and_belongs_to_many :users
  has_and_belongs_to_many :groups, join_table: :media_stores_groups
  has_many :media_store_users
  has_many :media_store_groups
end
