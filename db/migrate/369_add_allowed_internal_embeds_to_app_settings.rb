class AddAllowedInternalEmbedsToAppSettings < ActiveRecord::Migration
  def change
    add_column :app_settings, :allowed_internal_embeds, :string, array: true, default: []
  end
end
