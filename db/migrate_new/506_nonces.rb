class Nonces < ActiveRecord::Migration[5.2]
  include Madek::MigrationHelper

  def up
    execute <<-SQL.strip_heredoc
      CREATE TABLE nonces (
        id UUID NOT NULL PRIMARY KEY,
        keep_until timestamp with time zone NOT NULL DEFAULT now() + interval '1 hour'
      );
      CREATE INDEX keep_until_idx ON nonces (keep_until);
    SQL
  end


  def down
    drop_table :nonces
  end
end

