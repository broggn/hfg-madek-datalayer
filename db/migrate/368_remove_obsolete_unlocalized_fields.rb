class RemoveObsoleteUnlocalizedFields < ActiveRecord::Migration

  # follows up migrations 360-365. values were already migrated, just removed columns.

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
