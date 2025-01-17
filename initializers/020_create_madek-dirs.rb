require 'madek/constants'

Rails.application.reloader.to_prepare do
  [Madek::Constants::FILE_STORAGE_DIR,
   Madek::Constants::THUMBNAIL_STORAGE_DIR].each do |dir|
    Madek::System.execute_cmd! %(mkdir -p "#{dir}")
  end
  [Madek::Constants::FILE_STORAGE_DIR,
   Madek::Constants::THUMBNAIL_STORAGE_DIR].each do |dir|
    (0..15).map { |x| x.to_s(16) }.each do |sub_dir|
      Madek::System.execute_cmd! %(mkdir -p "#{dir}/#{sub_dir}")
    end
  end
end
