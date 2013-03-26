require 'framework/naming_tools'


class AddRequiredParameters < ActiveRecord::Migration

  def up
    say 'creating a parameter row for each controller...'

    AppParameter.transaction do                     # -- START TRANSACTION --
      NamingTools::PARAM_CTRL_SYMS.each { |ctrl_sym|
        code = get_code_for_ctrl( ctrl_sym )
        common_attr_hash = {                        # Prepare the hash of attributes that surely will go into the parameter row:
            :code => code,
            AppParameter::CTRL_NAME_FIELD.to_sym => ctrl_sym.to_s,
            AppParameter::PAGINATION_ENABLE_FIELD.to_sym => false,
            AppParameter::PAGINATION_ROWS_FIELD.to_sym => 20,
            AppParameter::FILTERING_RADIUS_FIELD.to_sym => 180,
            AppParameter::FILTERING_STRFTIME_FIELD.to_sym => '%Y-1-1',
            :description => "Dedicated parameter row for controller defaults.\r\n\r\n" +
                            "- controller_name: name of the controller which uses this row\r\n" +
                            "- range_x: default pagination backwards range in days (applied from current date)\r\n" +
                            "- range_y: max pagination rows\r\n" +
                            "- free_text_1: string format for range_x approx. (when present)"
        }
                                                    # Save the row:
        say "adding param. row for controller #{ctrl_sym} w/ code #{code}"
  # DEBUG
        say "DEBUG: attribute hash:\r\n===((#{common_attr_hash.inspect}))==="
        AppParameter.create common_attr_hash
      }
    end                                             # -- END TRANSACTION --

    say 'verifying the existence of the parameters...'
    NamingTools::PARAM_CTRL_SYMS.each { |ctrl_sym|
      code = get_code_for_ctrl( ctrl_sym )
      say "seeking param. row for controller #{ctrl_sym} w/ code #{code}"
      raise "Parameter row not found with code #{code}!" unless AppParameter.find_by_code( code )
    }
    say 'done.'
  end


  def down
    say 'deleting all new parameters rows for each controller...'
    NamingTools::PARAM_CTRL_SYMS.each { |ctrl_sym|
      code = get_code_for_ctrl( ctrl_sym )
      say "deleting param. row for controller #{ctrl_sym} w/ code #{code}"
      AppParameter.where( :code => code ).delete_all
    }
    say 'done.'
  end


  private


  def get_code_for_ctrl( ctrl_sym )
    AppParameter::PARAM_CTRL_START + NamingTools::PARAM_CTRL_SYMS.index( ctrl_sym ) * AppParameter::PARAM_CTRL_CODE_STEP
  end
end
