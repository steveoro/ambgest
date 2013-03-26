class ClearUnusedRowsInAppParameter < ActiveRecord::Migration
  def up
    AppParameter.delete_all( '(id >= 100000)' )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
