class RenameTooltipWidthToViewHeight < ActiveRecord::Migration
  def change
    rename_column :app_parameters, :tooltip_width, :view_height
  end
end
