class CreateWorkflows < ActiveRecord::Migration
  include Madek::MigrationHelper

  def change
    create_table :workflows, id: false do |t|
      t.primary_key :id, :uuid, default: 'gen_random_uuid()'
      t.timestamps null: false, default: 'now'
      t.string :name
    end

    execute <<-SQL.strip_heredoc
      ALTER TABLE workflows ADD COLUMN data jsonb DEFAULT '{}' NOT NULL
    SQL

  end
end
