# user is the system oriented representation of a User

require 'net/ldap'
require 'net/ldap/dn'

class User < ApplicationRecord
  include Concerns::FindResource
  include Concerns::Users::Delegations
  include Concerns::Users::Filters
  include Concerns::Users::Keywords
  include Concerns::Users::ResourcesAssociations
  include Concerns::Users::Workflows


  #############################################################################


  attr_accessor 'act_as_uberadmin'

  default_scope { reorder(:login) }

  belongs_to :person, -> { where(subtype: 'Person') }
  accepts_nested_attributes_for :person

  has_many :unpublished_media_entries,
           -> { where(is_published: false) },
           foreign_key: :creator_id,
           class_name: 'MediaEntry',
           dependent: :destroy

  has_many :created_media_entries,
           class_name: 'MediaEntry',
           foreign_key: :creator_id

  #############################################################

  has_many :created_custom_urls, class_name: 'CustomUrl', foreign_key: :creator_id
  has_many :updated_custom_urls, class_name: 'CustomUrl', foreign_key: :updator_id

  has_and_belongs_to_many :groups
  has_one :admin, dependent: :destroy
  belongs_to :accepted_usage_terms, class_name: 'UsageTerms'


  has_and_belongs_to_many :auth_systems

  #############################################################

  validates_format_of \
    :email,
    with: /@/, message: "The email must contain a '@' sign."

  #############################################################

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  #############################################################

  def admin?
    !admin.nil?
  end

  #############################################################

  def reset_usage_terms
    update!(accepted_usage_terms_id: nil)
  end

  ### password authentication #################################

  attr_accessor :password

  after_create :save_new_password

  def save_new_password
    if @password.presence
      sql= <<-SQL.strip_heredoc
        INSERT INTO auth_systems_users (auth_system_id, user_id, data)
        SELECT 'password', :user_id , crypt(:password, gen_salt('bf')) 
        ON CONFLICT (user_id, auth_system_id)
        DO UPDATE SET data = crypt(:password, gen_salt('bf'))
      SQL
      ActiveRecord::Base.connection.execute(
        ApplicationRecord.sanitize_sql([sql, user_id: self.id, password: @password]))
    end
  end

  def ldap_authenticate(pw)
    ldap = Net::LDAP.new :host => "ldap.hfg-karlsruhe.de",
                         :port => "ldaps",
                         :encryption => {
                           :method => :simple_tls
                         },
                         :auth => {
                           :method => :simple
                         },
                         :base => 'ou=people,dc=hfg-karlsruhe,dc=de',
                         :filter => "(uid=%u)"

    dn = Net::LDAP::DN.new 'uid', self.login, 'ou=people,dc=hfg-karlsruhe,dc=de'
    ldap.auth dn, pw
    if ldap.bind
      email = nil
      sn = nil
      givenName = nil
      ldap.search(:base => dn) do |entry|
        if entry[:mail]
          email = entry[:mail].first
        end
        if entry[:sn]
          sn = entry[:sn].first
        end
        if entry[:givenName]
          givenName = entry[:givenName].first
        end
      end
      self.create_person(:first_name => givenName, :last_name => sn)
      self.email = email
      self.password = pw
      self.save
      self.save_new_password
    else
      nil
    end
  end
  
  def sql_authenticate(pw)
    sql= <<-SQL.strip_heredoc
        SELECT (auth_systems_users.data = crypt(:password, auth_systems_users.data)) AS pw_matches 
        FROM auth_systems_users
        JOIN users ON auth_systems_users.user_id = users.id
        WHERE users.id = :user_id
        AND users.is_deactivated = false
        AND auth_systems_users.auth_system_id = 'password'
        AND ( auth_systems_users.expires_at IS NULL
              OR auth_systems_users.expires_at < NOW() )
    SQL
    res = ActiveRecord::Base.connection.execute(
      ApplicationRecord.sanitize_sql([sql, password: pw, user_id: self.id]))
    res.first["pw_matches"] && self
  rescue
    nil
  end

  #def authenticate(pw)
  #  sql_authenticate(pw) || ldap_authenticate(pw)
  #end


  #############################################################

  def can_edit_permissions_for?(resource)
    resource.responsible_user == self or
      resource.delegation_with_user?(self) or
      resource
        .user_permissions
        .where(user_id: id, edit_permissions: true).exists? or
      Permissions::UserPermission.permitted_for?(:edit_permissions, resource: resource, user: self)
  end
end
