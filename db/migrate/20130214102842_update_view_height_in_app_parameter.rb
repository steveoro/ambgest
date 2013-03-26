require 'framework/naming_tools'


class UpdateViewHeightInAppParameter < ActiveRecord::Migration

  def up
    say "updating '#{AppParameter::VIEW_HEIGHT_FIELD}' in parameter row for each controller..."
    AppParameter.transaction do                     # -- START TRANSACTION --
      NamingTools::PARAM_CTRL_SYMS.each { |ctrl_sym|
        code = get_code_for_ctrl( ctrl_sym )
        say "updating '#{AppParameter::VIEW_HEIGHT_FIELD}' in param.row for controller #{ctrl_sym} (code #{code})..."
        AppParameter.update_all(
          "#{ AppParameter::VIEW_HEIGHT_FIELD }=600", # updates
          "code=#{ code }"                          # conditions
        )
      }
    end                                             # -- END TRANSACTION --
    say 'done.'
  end


  def down
    say "clearing '#{AppParameter::VIEW_HEIGHT_FIELD}' in parameter row for each controller..."
    AppParameter.transaction do                     # -- START TRANSACTION --
      NamingTools::PARAM_CTRL_SYMS.each { |ctrl_sym|
        code = get_code_for_ctrl( ctrl_sym )
        say "clearing '#{AppParameter::VIEW_HEIGHT_FIELD}' in param.row for controller #{ctrl_sym} (code #{code})..."
        AppParameter.update_all(
          "#{ AppParameter::VIEW_HEIGHT_FIELD }=0", # updates
          "code=#{ code }"                          # conditions
        )
        AppParameter.update( code, AppParameter::VIEW_HEIGHT_FIELD.to_sym => 0 )
      }
    end                                             # -- END TRANSACTION --
    say 'done.'
  end


  private


  def get_code_for_ctrl( ctrl_sym )
    AppParameter::PARAM_CTRL_START + NamingTools::PARAM_CTRL_SYMS.index( ctrl_sym ) * AppParameter::PARAM_CTRL_CODE_STEP
  end
end
