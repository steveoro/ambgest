class AddAccessLevelForReceiptActions < ActiveRecord::Migration
  def up
    say "adding access restrictions for Receipt customized CRUD actions..."

    AppParameter.transaction do                     # -- START TRANSACTION --
      ap = AppParameter.find_by_code( AppParameter::PARAM_BLACKLIST_ACCESS_START + 20 )
      if (ap.nil?)                                  # Manual or "Free-field" creation of Receipts:
        AppParameter.create :code => AppParameter::PARAM_BLACKLIST_ACCESS_START + 20,
                            :controller_name => 'receipts',
                            :action_name => 'free_add',
                            :a_integer => 9,
                            :description => '(controller_name, action_name): action identifiers; a_integer: required level for access grant (should be greater than base level required for controller access)'
      end

      ap = AppParameter.find_by_code( AppParameter::PARAM_BLACKLIST_ACCESS_START + 22 )
      if (ap.nil?)                                  # Manual or "Free-field" editing of Receipts:
        AppParameter.create :code => AppParameter::PARAM_BLACKLIST_ACCESS_START + 22,
                            :controller_name => 'receipts',
                            :action_name => 'free_edit',
                            :a_integer => 9,
                            :description => '(controller_name, action_name): action identifiers; a_integer: required level for access grant (should be greater than base level required for controller access)'
      end

      ap = AppParameter.find_by_code( AppParameter::PARAM_BLACKLIST_ACCESS_START + 24 )
      if (ap.nil?)                                  # Manual or "Free" deletion of Receipts:
        AppParameter.create :code => AppParameter::PARAM_BLACKLIST_ACCESS_START + 24,
                            :controller_name => 'receipts',
                            :action_name => 'del',
                            :a_integer => 9,
                            :description => '(controller_name, action_name): action identifiers; a_integer: required level for access grant (should be greater than base level required for controller access)'
      end
    end                                             # -- END TRANSACTION --

    say 'verifying the existence of the parameters...'
    [
      AppParameter::PARAM_BLACKLIST_ACCESS_START + 20,
      AppParameter::PARAM_BLACKLIST_ACCESS_START + 22,
      AppParameter::PARAM_BLACKLIST_ACCESS_START + 24
    ].each { |code|
      say "seeking param. row w/ code #{code}"
      raise "Parameter row not found with code #{code}!" unless AppParameter.find_by_code( code )
    }
    say 'done.'
  end


  def down
    say "deleting access restrictions for Receipt customized CRUD actions..."
    AppParameter.delete_all(
      "(code >= #{AppParameter::PARAM_BLACKLIST_ACCESS_START + 20}) AND (code <= #{AppParameter::PARAM_BLACKLIST_ACCESS_START + 24})"
    )
    say 'done.'
  end
end
