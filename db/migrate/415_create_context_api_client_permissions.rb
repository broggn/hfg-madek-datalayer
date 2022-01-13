class CreateContextApiClientPermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :context_api_client_permissions, id: false do |t|
      t.primary_key :id, :uuid, default: 'gen_random_uuid()'
      t.references :api_client, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :context, foreign_key: { on_delete: :cascade }, type: :string, index: true
      t.boolean :view, default: true, null: false
    end

    add_index :context_api_client_permissions, [:api_client_id, :context_id], unique: true,
              name: 'context_api_client_permissions_unique_compound_index'
  end
end
