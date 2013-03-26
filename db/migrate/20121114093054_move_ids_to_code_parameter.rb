class MoveIdsToCodeParameter < ActiveRecord::Migration
  def up
    AppParameter.update_all( 'code = id', 'id > 0' )
    add_index :app_parameters, [:code], :name => 'code', :unique => true
  end

  def down
    remove_index :app_parameters, :name => 'code'
  end
end
