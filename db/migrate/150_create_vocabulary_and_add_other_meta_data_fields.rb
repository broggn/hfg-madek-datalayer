class CreateVocabularyAndAddOtherMetaDataFields < ActiveRecord::Migration

  def change
    rename_column :meta_keys, :meta_terms_alphabetical_order, :keywords_alphabetical_order

    # from meta_keys_definitions
    #
    add_column :meta_keys, :label, :text
    add_column :meta_keys, :description, :text
    add_column :meta_keys, :hint, :text
    add_column :meta_keys, :is_required, :boolean, default: false

    add_column :meta_keys, :length_max, :integer
    add_column :meta_keys, :length_min, :integer
    add_column :meta_keys, :position, :integer
    add_column :meta_keys, :input_type, :integer

    # Scope
    add_column :meta_keys, :is_enabled_for_media_entries, :bool, null: false, default: false
    add_column :meta_keys, :is_enabled_for_collections, :bool, null: false, default: false
    add_column :meta_keys, :is_enabled_for_filter_sets, :bool, null: false, default: false

    # Vocabulary
    create_table :vocabularies, id: :string do |t|
      t.text :label
      t.text :description
    end

    add_column :meta_keys, :vocabulary_id, :string

#    create_table :vocables, id: :uuid do |t|
#      t.string :meta_key_id
#      t.index :meta_key_id
#
#      t.text :term
#    end
#
#    create_table :meta_data_vocables, id: false do |t|
#      t.uuid :meta_datum_id
#      t.uuid :vocable_id
#      t.index [:meta_datum_id, :vocable_id], unique: true
#      t.index [:vocable_id, :meta_datum_id]
#    end
 
    add_column :keywords, :meta_key_id, :string
    add_index :keywords, :meta_key_id

    add_column :meta_keys, :is_extensible, :bool, default: false
  end

end
