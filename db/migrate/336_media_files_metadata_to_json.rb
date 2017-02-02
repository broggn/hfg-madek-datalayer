class MediaFilesMetadataToJson < ActiveRecord::Migration

  # old: media_files.meta_data stored as YAML text
  # new: jsonb
  # NOTE: keep the YAML because it is the cache for the raw data and has all the types
  # The JSON version is for fast display and PSQL access to hash keys

  class ::MigrationMediaFile < ActiveRecord::Base
    self.table_name = 'media_files'
  end


  def up
    count = MigrationMediaFile.all.count
    Rails.logger.info "Migrating MediaFiles Metadata To Json (N=#{count})"

    add_column :media_files, :meta_data_json, :jsonb
    change_column :media_files, :meta_data_json, \
      'jsonb USING CAST(meta_data_json AS jsonb)', default: {}, null: false

    MigrationMediaFile.reset_column_information

    MigrationMediaFile.all.each.with_index do |mf, n|
      Rails.logger.info "MediaFile: #{n + 1}/#{count}" if (n % 100) === 0

      value_string = '{}' # default

      if (current = mf.meta_data).present?
        # if any of this fails, data was complete garbage
        begin
          # NOTE: removes invalid string-encoded binary values and fixes utf-as-ascii
          value_string = YAML.load(current)
            .map do |k, v|
              next [k, v] unless v.is_a?(String)
              unless v.include?("\x00") || (!v.ascii_only? && !v.force_encoding('utf-8').valid_encoding?)
                [k, v.to_nfc]
              end
            end
            .compact.to_h
            .to_json
        rescue => e
          binding.pry
          Rails.logger.warn \
            "Discarding invalid file metadata for MediaFile '#{mf.id}'! Error: #{e}"
        end
      end

      mf.update_attribute(:meta_data_json, value_string)
      mf.save!
    end

    rename_column :media_files, :meta_data, :meta_data_raw
    rename_column :media_files, :meta_data_json, :meta_data
  end

end
