class AddAccessLevelParameters < ActiveRecord::Migration
  def up
    total = AppParameter::PARAM_ACCESS_LEVEL_END - AppParameter::PARAM_ACCESS_LEVEL_START + 1
    say "creating #{total} compulsory access level parameters"

    AppParameter.transaction do                     # -- START TRANSACTION --
      total.times { |access_level|
        AppParameter.create :code => AppParameter::PARAM_ACCESS_LEVEL_START + access_level,
                            :a_integer => access_level,
                            :free_text_1 => '',
                            :description => 'a_integer: access level; free_text_1: list of controller names for access grant, separated by comma'
      }
    end                                             # -- END TRANSACTION --

    say 'verifying the existence of the parameters...'
    total.times { |access_level|
      code = AppParameter::PARAM_ACCESS_LEVEL_START + access_level
      say "seeking param. row w/ code #{code}"
      raise "Parameter row not found with code #{code}!" unless AppParameter.find_by_code( code )
    }
    say 'done.'
  end


  def down
    say 'deleting all compulsory access level parameters'
    AppParameter.delete_all(
      "(code >= #{AppParameter::PARAM_ACCESS_LEVEL_START}) AND (code <= #{AppParameter::PARAM_ACCESS_LEVEL_END})"
    )
    say 'done.'
  end
end
