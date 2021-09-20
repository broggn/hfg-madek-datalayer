class Analyzers < ActiveRecord::Migration[5.2]
  include Madek::MigrationHelper

  def up
    execute <<-SQL.strip_heredoc
      CREATE TABLE analyzers (
        id text NOT NULL,
        description text,
        enabled boolean DEFAULT true NOT NULL,
        external boolean DEFAULT true,
        public_key text,
        CONSTRAINT internal CHECK
          ((external = false AND id = 'internal' AND public_key IS NULL) OR (external = true)),
        CONSTRAINT external CHECK
          ((external = true AND (enabled = false OR enabled = true AND public_key IS NOT NULL)) OR (external = false)),
        CONSTRAINT simple_id CHECK ((id ~ '^[a-z0-9]+[a-z0-9.-]+[a-z0-9]+$'::text))
      );
      ALTER TABLE analyzers ADD PRIMARY KEY (id);
    SQL
    add_auto_timestamps :analyzers
  end


  def down
    execute <<-SQL.strip_heredoc
      DROP TABLE IF EXISTS analyzers;
    SQL
  end
end

