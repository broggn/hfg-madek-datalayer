class Delegation < ApplicationRecord
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :users
  has_many :media_entries, foreign_key: :responsible_delegation_id
  has_many :collections, foreign_key: :responsible_delegation_id

  validates :name, presence: true, uniqueness: true

  def self.apply_sorting(sorting)
    if allowed_sortings.key?(sorting&.to_sym)
      current_scope.order(allowed_sortings[sorting.to_sym])
    else
      current_scope.order(allowed_sortings[:name])
    end
  end

  def self.allowed_sortings
    {
      name: 'name ASC',
      members_count: 'members_count DESC',
      resources_count: 'resources_count DESC'
    }
  end

  def self.with_members_count
    select('delegations.*, '\
      '(COUNT(delegations_groups.group_id) + COUNT(delegations_users.user_id)) AS members_count')
      .joins('LEFT OUTER JOIN delegations_groups '\
             'ON delegations_groups.delegation_id = delegations.id')
      .joins('LEFT OUTER JOIN delegations_users '\
             'ON delegations_users.delegation_id = delegations.id')
      .group('delegations.id')
  end

  def self.with_resources_count
    select('delegations.*, (COUNT(media_entries.id) + COUNT(collections.id)) AS resources_count')
      .joins('LEFT OUTER JOIN media_entries '\
             'ON media_entries.responsible_delegation_id = delegations.id')
      .joins('LEFT OUTER JOIN collections ON '\
             'collections.responsible_delegation_id = delegations.id')
      .group('delegations.id')
  end

  def self.filter_by(term, group_or_user_id = nil)
    result = current_scope

    if term.present?
      result = result.where('delegations.name ILIKE ?', "%#{term}%")
    end

    if group_or_user_id.present? && valid_uuid?(group_or_user_id)
      result = result
        .joins(:users, :groups)
        .where('users.id = :id OR groups.id = :id', id: group_or_user_id)
    end

    result
  end
end
