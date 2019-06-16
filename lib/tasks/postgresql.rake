namespace :postgresql do
  # https://github.com/coderdojo-japan/coderdojo.jp/blob/master/docs/how-to-update-db-id.md
  # https://github.com/rails/rails/blob/ec8697bf0bfafff7d897fb50e322afe42ddc1623/activerecord/lib/active_record/connection_adapters/postgresql/schema_statements.rb#L289-L315
  desc '全てのテーブルのsequenceを既存のidの最大値に設定しなおす'
  task reset_pk_sequence: :environment do
    ignore_rails_tables = %w(schema_migrations ar_internal_metadata).freeze
    ApplicationRecord.connection.tap do |c|
      (c.tables - ignore_rails_tables).each { |t| c.reset_pk_sequence!(t) }
    end
  end
end
