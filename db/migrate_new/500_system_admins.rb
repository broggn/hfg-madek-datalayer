class SystemAdmins < ActiveRecord::Migration[5.2]

  def change

    create_table :system_admins, id: :uuid do |t|
      t.uuid :user_id, null: false
    end
    add_index :system_admins, :user_id, unique: true
    add_foreign_key :system_admins, :users, on_delete: :cascade

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          INSERT INTO system_admins (user_id)
            SELECT admins.user_id FROM admins ;
        SQL
      end
    end

  end

end
