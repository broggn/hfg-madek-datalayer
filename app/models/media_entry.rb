class MediaEntry < ActiveRecord::Base
  ################################################################################
  # NOTE: The standard `find` and `find_by_id` methods are extended/overridden in
  # app/models/concerns/media_resources/custom_urls in order to accomodate
  # custom_ids. One can thus search for a particular resource using either its
  # uuid or custom_id.
  # There are two possible use cases:
  # 1. raise if resource is not found => use `find`
  # 2. return nil if resource is not found => use `find_by_id`
  #
  # `find_by(...)` or `find_by!(...)` are DISABLED. If you want to further
  # narrow down the scope when searching with a custom_id then do it this way:
  # Ex. `MediaEntry
  #        .joins(:custom_urls)
  #        .where(custom_urls: { is_primary: true })
  #        .find('custom_id')
  ################################################################################

  VIEW_PERMISSION_NAME = :get_metadata_and_previews
  EDIT_PERMISSION_NAME = :edit_metadata
  MANAGE_PERMISSION_NAME = :edit_permissions

  include Concerns::Collections::Siblings
  include Concerns::MediaEntries::Filters
  include Concerns::MediaResources
  include Concerns::MediaResources::MetaDataArelConditions
  include Concerns::MediaResources::Editability
  include Concerns::MediaResources::Highlight

  has_one :media_file, dependent: :destroy

  has_many :collection_media_entry_arcs, class_name: Arcs::CollectionMediaEntryArc
  has_many :parent_collections,
           through: :collection_media_entry_arcs,
           source: :collection

  default_scope { where(is_published: true) }
  default_scope { reorder(:created_at, :id) }

  # NOTE: could possibly be made as a DB trigger
  validate :validate_existence_of_meta_data_for_required_context_keys,
           if: :is_published?
end
