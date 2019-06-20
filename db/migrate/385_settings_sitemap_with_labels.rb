class SettingsSitemapWithLabels < ActiveRecord::Migration
  class MigrationSetting < ActiveRecord::Base
    self.table_name = 'app_settings'
  end

  # OLD_FIELD_DEFAULT = [{'Medienarchiv ZHdK': 'http://medienarchiv.zhdk.ch'}, {'Madek Project on Github': 'https://github.com/Madek'}]
  NEW_FIELD_DEFAULT = [
    {
      url: 'http://medienarchiv.zhdk.ch',
      labels: { de: 'Medienarchiv ZHdK', en: 'Media Archiv ZHdK' }
    },
    {
      url: 'https://github.com/Madek',
      labels: { de: 'Madek-Projekt auf GitHub', en: 'Madek Project on GitHub' }
    }
  ]

  def change
    old_sitemap = MigrationSetting.first.sitemap
    new_sitemap = old_sitemap.map do |link|
      url = link.values.first
      label = link.keys.first
      labels = available_locales.map {|lang| {lang => label} }.reduce(&:merge)
      { url: url, labels: labels }
    end
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
