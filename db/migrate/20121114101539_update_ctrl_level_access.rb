class UpdateCtrlLevelAccess < ActiveRecord::Migration
  def up
    # [Steve, 20120217] Creates the basic configuration for each required access level in each controller: 
    AppParameter.update_all(
      "free_text_1='welcome, login'",
      "code=#{AppParameter::PARAM_ACCESS_LEVEL_START}"
    )
    AppParameter.update_all(
      "free_text_1='blog, setup'",
      "code=#{AppParameter::PARAM_ACCESS_LEVEL_START + 1}"
    )
    AppParameter.update_all(
      "free_text_1='appointments, invoiced_appointments, patients, receipts, schedules, week_plan'",
      "code=#{AppParameter::PARAM_ACCESS_LEVEL_START + 2}"
    )
                                                    # (Skip 1 "free" level for future dev.)
    AppParameter.update_all(
      "free_text_1=''",
      "code=#{AppParameter::PARAM_ACCESS_LEVEL_START + 4}"
    )
    AppParameter.update_all(
      "free_text_1='articles'",
      "code=#{AppParameter::PARAM_ACCESS_LEVEL_START + 5}"
    )
    AppParameter.update_all(
      "free_text_1='users'",
      "code=#{AppParameter::PARAM_ACCESS_LEVEL_START + 8}"
    )
    AppParameter.update_all(
      "free_text_1='app_parameters'",
      "code=#{AppParameter::PARAM_ACCESS_LEVEL_START + 9}"
    )
  end


  def down
    AppParameter.update_all(
      "free_text_1=''",
      "(code >= #{AppParameter::PARAM_ACCESS_LEVEL_START}) AND (code <= #{AppParameter::PARAM_ACCESS_LEVEL_END})"
    )
  end
end
