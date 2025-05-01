class AddPgStatStatementsExtension < ActiveRecord::Migration[7.0]
  def change
    reversible do |direction|
      direction.up do
        execute <<-SQL
          CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
        SQL
      end

      direction.down do
        execute <<-SQL
          DROP EXTENSION pg_stat_statements;
        SQL
      end
    end
  end
end
