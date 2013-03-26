class UpdateDbVersionTo303 < ActiveRecord::Migration
  def up
    AppParameter.update(
      AppParameter::PARAM_VERSIONING_CODE,
      AppParameter::PARAM_APP_NAME_FIELD.to_sym => 'core-five',
      AppParameter::PARAM_DB_VERSION_FIELD.to_sym => '3.03.20130214'
    )
  end

  def down
    AppParameter.update(
      AppParameter::PARAM_VERSIONING_CODE,
      AppParameter::PARAM_APP_NAME_FIELD.to_sym => 'core-five',
      AppParameter::PARAM_DB_VERSION_FIELD.to_sym => '3.02.20130214'
    )
  end
end
