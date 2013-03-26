=begin
  
= AppParameterCustomizations

  - version:  3.02.20130206
  - author:   Steve A.
  - custom version for the application: AmbGest

=end
module AppParameterCustomizations
                                # Custom param ID codes:
  CODE_RECEIPT_DESCRIPTION      = 10 unless defined?(CODE_RECEIPT_DESCRIPTION)
  CODE_RECEIPT_ALT_DESCRIPTION  = 12 unless defined?(CODE_RECEIPT_ALT_DESCRIPTION)

  CODE_APPOINTMENT_MINS         = 20 unless defined?(CODE_APPOINTMENT_MINS)
  CODE_MORNING_SCHEDULE         = 22 unless defined?(CODE_MORNING_SCHEDULE)
  CODE_NOON_SCHEDULE            = 24 unless defined?(CODE_NOON_SCHEDULE)

  CODE_RECEIPT_COSTS_START      = 30 unless defined?(CODE_RECEIPT_COSTS_START)
  CODE_RECEIPT_COSTS_END        = 39 unless defined?(CODE_RECEIPT_COSTS_END)

  CODE_RECEIPT_ACCOUNT_PERCENT  = 40 unless defined?(CODE_RECEIPT_ACCOUNT_PERCENT)
  #----------------------------------------------------------------------------


  # Retrieves the default receipt (/invoice) description.
  #
  def self.get_default_receipt_description()
    ::ActiveSupport::Deprecation.warn("'AppParameter.get_default_receipt_description()' is deprecated and does not support localization. Use 'as_(:default_receipt_description, {:scope=>[:agex]})' instead.")
    AppParameter.get_string_parameter( CODE_RECEIPT_DESCRIPTION )
  end

  # Retrieves the alternate receipt (/invoice) description.
  def self.get_alternate_receipt_description()
    ::ActiveSupport::Deprecation.warn("'AppParameter.get_alternate_receipt_description()' is deprecated and does not support localization. Use 'as_(:alternate_receipt_description, {:scope=>[:agex]})' instead.")
    AppParameter.get_string_parameter( CODE_RECEIPT_ALT_DESCRIPTION )
  end
  # ---------------------------------------------------------------------------
  #++


  # Retrieves the default appointment length in minutes from the Application's
  # Parameters configuration table.
  def self.get_appointment_length_in_mins()
    ap = AppParameter.find_by_id( CODE_APPOINTMENT_MINS )
    ap.nil? ? 60 : ap.a_integer
  end

  # Retrieves the morning appointment scheduling and prepares an hash containing:
  #
  # :start_time => a DateTime instance of the starting time (date part should be ignored);
  # :total_appointments => the total number of appointement to be scheduled as default.
  #
  def self.get_morning_schedule()
    prepare_schedule_hash( CODE_MORNING_SCHEDULE, "08:30" )
  end

  # Retrieves the noon appointment scheduling and prepares an hash containing:
  #
  # :start_time => a DateTime instance of the starting time (date part should be ignored);
  # :total_appointments => the total number of appointement to be scheduled as default.
  #
  def self.get_noon_schedule()
    prepare_schedule_hash( CODE_NOON_SCHEDULE, "13:30" )
  end
  # ---------------------------------------------------------------------------
  #++


  # Retrieves an array of hashes each one containing the pair:
  # :name => description of the receipt cost row;
  # :value => value (in euro cents) for this cost row.
  def self.get_receipt_costs()
    costs = []
    param_found = AppParameter.find( :all,  :conditions => ['(id >= ? and id <= ?)', CODE_RECEIPT_COSTS_START,  CODE_RECEIPT_COSTS_END] )
    param_found.each { |p| ( costs << {:name => p.a_string, :value => p.a_integer} ) }
    return costs
  end


  # Retrieves the description for the default account percent used in a receipt.
  def self.get_receipt_account_description()
    AppParameter.get_string_parameter( CODE_RECEIPT_ACCOUNT_PERCENT )
  end

  # Retrieves the integer value for the default account percent used in a receipt.
  def self.get_receipt_account_percent()
    AppParameter.get_integer_parameter( CODE_RECEIPT_ACCOUNT_PERCENT )
  end
  # ---------------------------------------------------------------------------
  #++


  private


  # Retrieves appointment scheduling and prepares an hash containing:
  #
  # :start_time => a DateTime instance of the starting time (date part should be ignored);
  # :total_appointments => the total number of appointement to be scheduled as default.
  #
  def self.prepare_schedule_hash( schedule_app_parameter_id, starting_time_string )
    ap = AppParameter.find_by_id( schedule_app_parameter_id )
    if ap.nil?
      sTemp = Date.today.year.to_s << "-" << "%02u" % Date.today.month.to_s << "-" << 
              "%02u" % Date.today.day.to_s << " " << starting_time_string
      start_time = DateTime.parse(sTemp)
      total_appointments = 4
    else
      start_time = ap.a_date
      total_appointments = ap.a_integer
    end
    return {
      :start_time => start_time, :total_appointments => total_appointments,
      :start_hour => start_time.hour, :start_min => start_time.min
    }
  end
  # ---------------------------------------------------------------------------
  #++
end
#------------------------------------------------------------------------------