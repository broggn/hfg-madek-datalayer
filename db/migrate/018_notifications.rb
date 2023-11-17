class Notifications < ActiveRecord::Migration[6.1]
  include Madek::MigrationHelper

  def up
    create_table(:notifications, id: :uuid) do |t|
      t.uuid(:user_id, null: false)
      t.boolean(:is_acknowledged, null: false, default: false)
      t.text(:content, null: false)
      t.uuid(:email_id, null: true)
    end
    add_auto_timestamps :notifications

    create_table(:notifications_settings, id: :uuid) do |t|
      t.uuid(:user_id, null: false)
      t.boolean(:deliver_via_email, null: false, default: false)
      t.boolean(:deliver_via_ui, null: false, default: false)
      t.string(:deliver_via_email_regularity, null: false, default: 'immediately')
    end
    add_auto_timestamps :notifications_settings

    execute <<-SQL
      ALTER TABLE notifications_settings
      ADD CONSTRAINT check_email_regularity_value
      CHECK ( deliver_via_email_regularity IN ('immediately', 'daily', 'weekly') );
    SQL

  end

  def down
    drop_table(:notifications)
    drop_table(:notifications_settings)
  end
end
