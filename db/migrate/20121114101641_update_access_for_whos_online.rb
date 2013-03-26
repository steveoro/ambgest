class UpdateAccessForWhosOnline < ActiveRecord::Migration
  def up
    say "adding access restrictions for some customized actions..."

    AppParameter.transaction do                     # -- START TRANSACTION --
      ap = AppParameter.find_by_code( AppParameter::PARAM_BLACKLIST_ACCESS_START )
      if (ap.nil?)
        AppParameter.create :code => AppParameter::PARAM_BLACKLIST_ACCESS_START,
                            :controller_name => 'week_plan',
                            :action_name => 'income_analysis',
                            :a_integer => 4,        # (higher than projects)
                            :description => '(controller_name, action_name): action identifiers; a_integer: required level for access grant (should be greater than base level required for controller access)'
      end
                                                    # (Let's say 5 is enough as a step in between action restrictions - it won't be read or needed anywhere else)
      ap = AppParameter.find_by_code( AppParameter::PARAM_BLACKLIST_ACCESS_START + 5 )
      if (ap.nil?)
        AppParameter.create :code => AppParameter::PARAM_BLACKLIST_ACCESS_START + 5,
                            :controller_name => 'appointments',
                            :action_name => 'issue_receipt',
                            :a_integer => 4,        # (same level as contacts, firms, ...)
                            :description => '(controller_name, action_name): action identifiers; a_integer: required level for access grant (should be greater than base level required for controller access)'
      end

      ap = AppParameter.find_by_code( AppParameter::PARAM_BLACKLIST_ACCESS_START + 10 )
      if (ap.nil?)
        AppParameter.create :code => AppParameter::PARAM_BLACKLIST_ACCESS_START + 10,
                            :controller_name => 'welcome',
                            :action_name => 'whos_online',
                            :a_integer => 8,        # (same level as contacts, firms, ...)
                            :description => '(controller_name, action_name): action identifiers; a_integer: required level for access grant (should be greater than base level required for controller access)'
      end

      ap = AppParameter.find_by_code( AppParameter::PARAM_BLACKLIST_ACCESS_START + 15 )
      if (ap.nil?)
        AppParameter.create :code => AppParameter::PARAM_BLACKLIST_ACCESS_START + 15,
                            :controller_name => 'welcome',
                            :action_name => 'edit_current_user',
                            :a_integer => 1,
                            :description => '(controller_name, action_name): action identifiers; a_integer: required level for access grant (should be greater than base level required for controller access)'
      end
    end                                             # -- END TRANSACTION --

    say 'verifying the existence of the parameters...'
    [
      AppParameter::PARAM_BLACKLIST_ACCESS_START,
      AppParameter::PARAM_BLACKLIST_ACCESS_START + 5,
      AppParameter::PARAM_BLACKLIST_ACCESS_START + 10,
      AppParameter::PARAM_BLACKLIST_ACCESS_START + 15
    ].each { |code|
      say "seeking param. row w/ code #{code}"
      raise "Parameter row not found with code #{code}!" unless AppParameter.find_by_code( code )
    }
    say 'done.'
  end


  def down
    say "deleting access restrictions for all customized actions..."
    AppParameter.delete_all(
      "(code >= #{AppParameter::PARAM_BLACKLIST_ACCESS_START}) AND (code <= #{AppParameter::PARAM_BLACKLIST_ACCESS_START + 15})"
    )
    say 'done.'
  end
end
