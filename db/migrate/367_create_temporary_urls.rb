class CreateTemporaryUrls < ActiveRecord::Migration
  include Madek::MigrationHelper

  def change
    create_table :temporary_urls, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.references :resource, polymorphic: true, index: true, type: :uuid
      t.string :token_hash, null: false, limit: 45
      t.string :token_part, null: false, limit: 5
      t.boolean :revoked, default: false, null: false
      t.text :description
    end

    add_auto_timestamps :temporary_urls

    add_foreign_key :temporary_urls, :users , on_delete: :cascade, on_update: :cascade

    add_column :temporary_urls, :expires_at, 'timestamp with time zone', null: false


    reversible do |dir|
      dir.up do
        execute "ALTER TABLE temporary_urls ALTER COLUMN expires_at SET DEFAULT now() + interval '1 year'"
        execute 'ALTER TABLE temporary_urls ADD UNIQUE ("token_hash")'
      end
    end
  end
end
