class RemoveObsoleteUnlocalizedFields < ActiveRecord::Migration

  # follows up migrations 360-365. values were already migrated, just removed columns.

  # TODO: also move available-/default-language settings to DB.
  #       then either deal with queries using the old col OR use computed column or something

  def up
    execute <<-SQL

    ALTER TABLE meta_keys
      DROP COLUMN label,
      DROP COLUMN description,
      DROP COLUMN hint;

    ALTER TABLE context_keys
      DROP COLUMN label,
      DROP COLUMN description,
      DROP COLUMN hint;

    SQL
  end

end
