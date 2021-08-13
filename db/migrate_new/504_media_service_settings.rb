class MediaServiceSettings < ActiveRecord::Migration[5.2]
  include Madek::MigrationHelper

  def up
    execute <<-SQL.strip_heredoc


      CREATE TABLE media_service_settings (
        id integer DEFAULT 0 NOT NULL,
        upload_min_part_size integer NOT NULL DEFAULT #{2 ** 20}, -- 1 MB
        upload_max_part_size integer NOT NULL DEFAULT #{2 ** 20 * 100}, -- 100 MB
        secret text NOT NULL DEFAULT encode(gen_random_bytes(32), 'base64'),
        previous_secret text NOT NULL DEFAULT encode(gen_random_bytes(32), 'base64'),
        secret_rollover_at timestamp with time zone DEFAULT now(),
        -- key_algo text CHECK (key_algo IN ('es256', 'es512', 'eddsa', 'rs256', 'rs512')),
        CONSTRAINT id_is_zero CHECK (id = 0)
      );

      CREATE OR REPLACE FUNCTION media_service_settings_secret_rollover()
      RETURNS TRIGGER AS $$
      BEGIN
        IF (NEW.secret = OLD.secret AND
             NEW.secret_rollover_at <= NOW() - interval '24 hours'
           ) THEN
           NEW.secret = encode(gen_random_bytes(32), 'base64');
        END IF;
        IF (NEW.secret <> OLD.secret) THEN
           NEW.secret_rollover_at = NOW();
           NEW.previous_secret = OLD.secret;
         END IF;
        RETURN NEW;
      END;
      $$ language 'plpgsql';

      CREATE TRIGGER media_service_settings_secret_rollover
      BEFORE UPDATE ON media_service_settings
      FOR EACH ROW EXECUTE PROCEDURE media_service_settings_secret_rollover();


    SQL
    add_auto_timestamps :media_service_settings
  end


  def down
    execute <<-SQL.strip_heredoc
      DROP TABLE IF EXISTS media_service_settings;
    SQL
  end
end

