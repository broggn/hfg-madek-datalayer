class MetaKey < ActiveRecord::Base

  include Concerns::MetaKeys::Filters

  has_many :meta_data, dependent: :destroy
  has_many :keywords
  belongs_to :vocabulary

  default_scope { order(:id) }
  scope :order_by_name_part, lambda {
    reorder("substring(meta_keys.id FROM ':(.*)$') ASC, meta_keys.id")
  }
  scope :with_keywords_count, lambda {
    joins(
      'LEFT OUTER JOIN keywords ON
       keywords.meta_key_id = meta_keys.id'
    )
      .select('meta_keys.*, count(keywords.id) as keywords_count')
      .group('meta_keys.id')
  }

  def self.object_types
    unscoped \
      .select(:meta_datum_object_type)
      .distinct
      .order(:meta_datum_object_type)
      .map(&:meta_datum_object_type)
  end

  def can_have_keywords?
    meta_datum_object_type == 'MetaDatum::Keywords'
  end

end
