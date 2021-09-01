class MediaServiceSettings < ActiveRecord::Migration[5.2]
  include Madek::MigrationHelper

  def up
    execute <<-SQL.strip_heredoc
      CREATE TABLE media_service_settings (
        id integer DEFAULT 0 NOT NULL,
        upload_min_part_size integer NOT NULL DEFAULT #{2 ** 20}, -- 1 MB
        upload_max_part_size integer NOT NULL DEFAULT #{2 ** 20 * 100}, -- 100 MB
        private_key text,
        CONSTRAINT id_is_zero CHECK (id = 0)
      );
    SQL
    add_auto_timestamps :media_service_settings
  end


  def down
    execute <<-SQL.strip_heredoc
      DROP TABLE IF EXISTS media_service_settings;
    SQL
  end
end

