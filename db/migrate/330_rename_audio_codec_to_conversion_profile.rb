class RenameAudioCodecToConversionProfile < ActiveRecord::Migration
  def change
    rename_column :media_files, :audio_codecs, :conversion_profiles
    rename_column :previews, :audio_codec, :conversion_profile
  end
end
