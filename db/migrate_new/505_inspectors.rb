class Inspectors < ActiveRecord::Migration[5.2]
  include Madek::MigrationHelper

  def up

    create_table :inspectors, id: :text
    add_column :inspectors, :description, :text
    add_column :inspectors, :enabled, :boolean, default: true, null: false
    add_column :inspectors, :public_key, :text
    execute <<-SQL.strip_heredoc
      ALTER TABLE inspectors
      ADD CONSTRAINT simple_id
      CHECK ((id ~ '^[a-z0-9]+[a-z0-9.-]+[a-z0-9]+$'::text))
    SQL
    add_auto_timestamps :inspectors

    # ;;;;;;;;;;;;;;;;;;;;

    create_table :inspector_pings, id: :text, primary_key: :inspector_id
    #add_column :inspector_pings, :inspector_id, :text, null: false
    add_column :inspector_pings, :last_ping_at, 'timestamp with time zone'
    add_foreign_key :inspector_pings, :inspectors, cascade: :delete


    # ;;;;;;;;;;;;;;;;;;;;

    create_table :inspections, id: :uuid

    add_column :inspections, :media_file_id, :uuid, null: false
    add_column :inspections, :raw_data, :jsonb
    add_column :inspections, :dispatched_at, 'timestamp with time zone'
    add_column :inspections, :finished_at, 'timestamp with time zone'
    add_foreign_key :inspections, :media_files, cascade: :delete

    add_column :inspections, :state, :text, default: 'pending', null: false
    execute <<-SQL.strip_heredoc
      ALTER TABLE inspections
        ADD CONSTRAINT state_check
        CHECK (state IN ('pending', 'dispatched', 'processing', 'failed', 'finished'));
    SQL

    add_column :inspections, :inspector_id, :text
    add_foreign_key :inspections, :inspectors, cascade: :nullify

    add_auto_timestamps :inspections


  end


  def down
    drop_table :inspections
    drop_table :inspector_pings
    drop_table :inspectors
  end
end

