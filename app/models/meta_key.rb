class MetaKey < ActiveRecord::Base

  include Concerns::MetaKeys::Filters
  include Concerns::Orderable

  has_many :meta_data, dependent: :destroy
  has_many :keywords
  belongs_to :vocabulary
  has_many :context_keys

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

  def self.viewable_by_user_or_public(user = nil)
    viewable_vocabs = Vocabulary.viewable_by_user_or_public(user)
    where(vocabulary_id: viewable_vocabs)
  end

  def viewable_by_user_or_public?(user = nil)
    viewable_meta_keys = self.class.viewable_by_user_or_public(user)
    viewable_meta_keys.include? self
  end

  def move_up
    move :up, vocabulary_id: vocabulary.id
  end

  def move_down
    move :down, vocabulary_id: vocabulary.id
  end
end
