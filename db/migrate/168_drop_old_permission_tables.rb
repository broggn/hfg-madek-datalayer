class DropOldPermissionTables < ActiveRecord::Migration[4.2]

  def change
    drop_table :userpermissions
    drop_table :applicationpermissions
    drop_table :grouppermissions

    drop_table :permission_presets
  end

end
