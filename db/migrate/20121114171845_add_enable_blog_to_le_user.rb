class AddEnableBlogToLeUser < ActiveRecord::Migration
  def change
    add_column :le_users, :enable_blog, :boolean, :default => false, :null => false, :after => :enable_setup
  end
end
