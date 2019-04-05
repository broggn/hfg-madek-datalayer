class RemoveLabelDescriptionAndHintFromContextKeys < ActiveRecord::Migration
  include Madek::MigrationHelper

  class MigrationContextKey < ActiveRecord::Base
    self.table_name = 'context_keys'
  end

  def change
    reversible do |dir|

      dir.up do
        remove_column :context_keys, :label
        remove_column :context_keys, :description
        remove_column :context_keys, :hint

        add_non_blank_constraints(MigrationContextKey.table_name, :labels, :descriptions, :hints)
      end

      dir.down do
        add_column :context_keys, :label, :text
        add_column :context_keys, :description, :text
        add_column :context_keys, :hint, :text

        ActiveRecord::Base.transaction do
          MigrationContextKey.find_each do |context_key|
            context_key.update_columns(
              label: context_key.labels[default_locale],
              description: context_key.descriptions[default_locale],
              hint: context_key.hints[default_locale]
            )
          end
        end

        %w(label description hint).each do |column_name|
          cmd = <<-SQL.strip_heredoc
            ALTER TABLE #{MigrationContextKey.table_name}
              ADD CONSTRAINT check_#{column_name}_not_blank
              CHECK (#{column_name} !~ '^\s*$');

            ALTER TABLE #{MigrationContextKey.table_name}
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
