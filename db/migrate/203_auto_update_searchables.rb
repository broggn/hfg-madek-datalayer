class AutoUpdateSearchables < ActiveRecord::Migration
  include Madek::MigrationHelper

  def change
    auto_update_searchable :people, [:first_name, :last_name, :pseudonym]
    auto_update_searchable :groups, [:name, :institutional_group_name]
    auto_update_searchable :users, [:login, :email]
  end
end
