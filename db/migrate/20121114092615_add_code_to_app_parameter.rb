class AddCodeToAppParameter < ActiveRecord::Migration
  def change
    # [Steve, 20120216] Working SQL: "ALTER TABLE  `app_parameters` ADD  `code` INT NOT NULL COMMENT  'unique access code' AFTER  `id`"
    add_column :app_parameters, :code, :integer, :default => 0, :null => false, :after => :id, :comment => 'unique access code'
  end
end
