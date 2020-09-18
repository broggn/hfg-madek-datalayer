class AddAlreadyOrderedManuallyToCollections < ActiveRecord::Migration[5.2]
  def change
    add_column :collections, :already_ordered_manually, :boolean, default: false, null: false
  end
end
