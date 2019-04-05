class RemoveLabelDescriptionAndHintFromMetaKeys < ActiveRecord::Migration
  include Madek::MigrationHelper

  class MigrationMetaKey < ActiveRecord::Base
    self.table_name = 'meta_keys'
  end

  def change
    reversible do |dir|

      dir.up do
        remove_column :meta_keys, :label
        remove_column :meta_keys, :description
        remove_column :meta_keys, :hint

        add_non_blank_constraints(MigrationMetaKey.table_name, :labels, :descriptions, :hints)
      end

      dir.down do
        add_column :meta_keys, :label, :text
        add_column :meta_keys, :description, :text
        add_column :meta_keys, :hint, :text

        ActiveRecord::Base.transaction do
          MigrationMetaKey.find_each do |mk|
            mk.update_columns(
              label: mk.labels[default_locale],
              description: mk.descriptions[default_locale],
              hint: mk.hints[default_locale]
            )
          end
        end

        %w(label description hint).each do |column_name|
          cmd = <<-SQL.strip_heredoc
            ALTER TABLE #{MigrationMetaKey.table_name}
              ADD CONSTRAINT check_#{column_name}_not_blank
              CHECK (#{column_name} !~ '^\s*$');

            ALTER TABLE #{MigrationMetaKey.table_name}
              ALTER COLUMN #{column_name} SET DEFAULT NULL;
          SQL
          execute cmd
        end
      end
    end
  end

  private

  def default_locale
    Settings.madek_default_locale
  end
end
