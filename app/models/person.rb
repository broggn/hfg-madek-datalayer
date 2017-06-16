class Person < ActiveRecord::Base
  include Concerns::FindResource
  include Concerns::People::Filters

  self.inheritance_column = false

  default_scope { reorder(:last_name) }
  scope :subtypes, -> { unscoped.select(:subtype).distinct }

  has_one :user

  has_and_belongs_to_many :meta_data, join_table: :meta_data_people

  validate do
    if [first_name, last_name, pseudonym].all?(&:blank?)
      errors.add(:base,
                 'Either first_name or last_name or pseudonym must have a value!')
    end
  end

  def to_s
    case
    when ((first_name or last_name) and (pseudonym and !pseudonym.try(:empty?)))
      "#{first_name} #{last_name} (#{pseudonym})".strip
    when (first_name or last_name)
      "#{first_name} #{last_name}".strip
    else
      pseudonym.strip
    end
  end

  # used in explore catalog
  def self.for_meta_key_and_used_in_visible_entries_with_previews(meta_key,
                                                                  user,
                                                                  limit)
    joins(meta_data: :meta_key)
      .where(meta_keys: { id: meta_key.id })
      .where(
        meta_data: {
          media_entry_id: MediaEntry
                          .viewable_by_user_or_public(user)
                          .joins(media_file: :previews)
                          .where(previews: { media_type: 'image' })
        }
      )
      .limit(limit)
  end

  def self.with_usage_count
    select('people.*, count(people.id) AS usage_count')
      .joins(:meta_data)
      .group('people.id')
      .reorder('usage_count DESC')
  end
end
