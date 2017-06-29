class AddBetaTesterGroupNewBrowse < ActiveRecord::Migration
  class ::MigrationGroup < ActiveRecord::Base
    self.table_name = 'groups'
  end

  def change
    # the id is UUIDTools::UUID.sha1_create(Madek::Constants::MADEK_UUID_NS, "beta_test_new_browse").to_s
    group = MigrationGroup.find_by(id: '1b7416e5-daff-5e4b-b97b-021bef493c03')
    group.destroy! if group
end
