class FixKeywordsExternalUris < ActiveRecord::Migration[5.2]
  def change
    execute <<-SQL.strip_heredoc
      UPDATE "keywords" SET "external_uris"='{}' WHERE "external_uris" IS NULL;
      ALTER TABLE "keywords" ALTER COLUMN "external_uris" SET NOT NULL;
    SQL
  end
end
