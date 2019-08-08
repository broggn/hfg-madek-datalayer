class MediaEntry < ApplicationRecord
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
  include Concerns::MediaResources::CustomOrderBy
  include Concerns::MediaResources::Editability
  include Concerns::MediaResources::Highlight
  include Concerns::MediaResources::MetaDataArelConditions
  include Concerns::SharedOrderBy
  include Concerns::SharedScopes

  has_one :media_file, dependent: :destroy

  has_many :collection_media_entry_arcs,
           class_name: 'Arcs::CollectionMediaEntryArc'
  has_many :parent_collections,
           through: :collection_media_entry_arcs,
           source: :collection

  has_many :confidential_links, as: :resource
  attr_accessor :accessed_by_confidential_link

  scope :ordered, -> { reorder(:created_at, :id) }
  scope :published, -> { where(is_published: true) }
  scope :not_published, -> { where(is_published: false) }
  scope :with_unpublished, -> { rewhere(is_published: [true, false]) }
  default_scope { published.ordered }

  # NOTE: could possibly be made as a DB trigger
  validate :validate_existence_of_meta_data_for_required_context_keys,
           if: :is_published?

  def self.joins_meta_data_title
    joins_meta_data_title_by_classname
  end

  def self.order_by_last_edit_session
    order_by_last_edit_session_by_classname
  end

  def workflow
    Workflow.find_by(id: MediaEntry.workflow_ids(id))
  end

  def part_of_workflow?
    MediaEntry.parent_collections(id).joins(:workflow).any?
  end

  def self.parent_collections(media_entry_id)
    Collection.where("collections.id IN (#{parent_collections_query(media_entry_id)})")
  end

  def self.parent_collections_query(media_entry_id)
    <<-SQL.strip_heredoc
      WITH RECURSIVE parents as (
        SELECT parent_id
        FROM collection_collection_arcs
        WHERE child_id IN (
          SELECT collection_id
          FROM collection_media_entry_arcs
          WHERE media_entry_id = '#{media_entry_id}'
        )
        UNION
        SELECT cca.parent_id
        FROM collection_collection_arcs cca
        JOIN parents p ON cca.child_id = p.parent_id
      )
      SELECT parent_id FROM parents
      UNION
      SELECT cmea.collection_id
      FROM collection_media_entry_arcs cmea
      WHERE media_entry_id = '#{media_entry_id}'
    SQL
  end

  def self.workflow_ids(media_entry_id)
    parent_collections(media_entry_id).joins(:workflow).pluck(:workflow_id)
  end
end
