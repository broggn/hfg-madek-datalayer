class Group < ApplicationRecord
  include Concerns::FindResource
  include Concerns::Groups::Filters
  include Concerns::Groups::Searches
  include Concerns::PreviousId

  has_and_belongs_to_many :users
  belongs_to :person
  has_and_belongs_to_many :delegations

  validates_presence_of :name
  validates :name, uniqueness: { scope: :institutional_name }

  scope :departments, -> { where(type: 'InstitutionalGroup') }
  scope :by_type, -> (type) { where(type: type) }

  def self.types
    unscoped \
      .select(:type)
      .distinct
      .order(:type)
      .map(&:type)
  end

  def merge_to(receiver)
    ActiveRecord::Base.transaction do
      merge_users_to(receiver)
      receiver.remember_id(id)
      destroy!
    end
  end

  def merge_users_to(receiver)
    users.each do |user|
      receiver.users << user unless receiver.users.exists?(id: user.id)
    end
    users.clear
  end

  def institutional?
    type == 'InstitutionalGroup'
  end
end
