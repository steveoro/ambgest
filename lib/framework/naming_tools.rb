require 'singleton'

#
# == NamingTools: Framework-specific naming convention tool class.
#
# A singleton utility class used to check and manage the framework naming conventions and the default access grant separation levels.
#
# (p) 2008-2013, FASAR Software, Italy
#
class NamingTools
  include Singleton


  public


  # List of all controller or "context" names that have a dedicated parameter row inside table app_parameters.
  # (Meaning "context" in the sense of either a controller or a +controller+<underscore>+action+ combination.
  # In the first case the implicit action is "index")
  #
  # This is used just to have a different "filtering resolution" or other dedicated rendering parameters
  # for any of the enlisted actions.
  #
  PARAM_CTRL_SYMS = [
    :appointments, :articles, :patients_manage, :patients, :receipts,
    :schedules, :week_plan, :welcome
  ]

  # Hash for all custom app_parameters column names used to store default values for each
  # controller of the application. Not all controller names need to be enlisted (nor they need
  # to have custom default values stored inside app_parameters).
  #
  DEFAULT_VALUES_IN_APP_PARAMETERS = {
  }
  # ---------------------------------------------------------------------------


  # Returns the <tt>app_parameters</tt>  column name (as string) used to store the default value for the couple
  # <tt>( controller_sym, field_sym )</tt> specified as symbols. Returns +nil+ if none was found.
  #
  def self.get_field_name_for_default_value_in_app_parameters_for( controller_sym, field_sym )
    field_hash = NamingTools::DEFAULT_VALUES_IN_APP_PARAMETERS[ controller_sym ]
    return field_hash[ field_sym ] unless field_hash.nil?
    nil
  end
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
end