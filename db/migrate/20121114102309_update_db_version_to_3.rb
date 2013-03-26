class UpdateDbVersionTo3 < ActiveRecord::Migration
  def up
    # [Steve, 20120216] (ASSERT: assuming the actual id for the PARAM_VERSIONING row is still equal to its code inside AppParameter)
    AppParameter.update(
      AppParameter::PARAM_VERSIONING_CODE,
      AppParameter::PARAM_APP_NAME_FIELD.to_sym => 'core-five',
      AppParameter::PARAM_DB_VERSION_FIELD.to_sym => '3.01.20120217'
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
