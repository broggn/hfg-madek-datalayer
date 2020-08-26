class AddBrandLogoMiniToAppSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :app_settings, :brand_logo_mini_url, :string, default: nil, null: true
  end
end
