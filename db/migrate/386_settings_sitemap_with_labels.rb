class SettingsSitemapWithLabels < ActiveRecord::Migration
  class MigrationSetting < ActiveRecord::Base
    self.table_name = 'app_settings'
  end

  # OLD_FIELD_DEFAULT = [
  #   {'Medienarchiv ZHdK': 'http://medienarchiv.zhdk.ch'},
  #   {'Madek Project on Github': 'https://github.com/Madek'}]

  NEW_FIELD_DEFAULT = {
    de: [
      { 'Medienarchiv ZHdK': 'http://medienarchiv.zhdk.ch' },
      { 'Madek-Projekt auf GitHub': 'https://github.com/Madek' }
    ],
    en: [
      { 'Media Archiv ZHdK': 'http://medienarchiv.zhdk.ch' },
      { 'Madek Project on Github': 'https://github.com/Madek' }
    ]
  }

  def change
    old_sitemap = MigrationSetting.first.sitemap.as_json
    new_sitemap = available_locales
      .map { |lang| { lang => old_sitemap } }
      .reduce(&:merge)
    MigrationSetting.first.update_attributes!(sitemap: new_sitemap)
    change_column_default(:app_settings, :sitemap, NEW_FIELD_DEFAULT)
  end

  private

  def default_locale
    MigrationSetting.first[:default_locale]
  end

  def available_locales
    MigrationSetting.first[:available_locales]
  end
end
