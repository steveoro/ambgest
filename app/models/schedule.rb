require 'common/format'


class Schedule < ActiveRecord::Base

  belongs_to :patient

  validates_associated :patient

  validates_presence_of :date_schedule
  validates_presence_of :patient_id

  validates_length_of :notes, :maximum => 255, :allow_nil => true

#  validates_format_of :must_insert_before_type_cast, :with => /[01]/, :message => I18n.t("Must be 1 or 0")
#  validates_format_of :must_move_before_type_cast, :with => /[01]/, :message => I18n.t("Must be 1 or 0")
#  validates_format_of :must_call_before_type_cast, :with => /[01]/, :message => I18n.t("Must be 1 or 0")
#  validates_format_of :is_done_before_type_cast, :with => /[01]/, :message => I18n.t("Must be 1 or 0")
  # Note: boolean validation via a typical...
  #
  #   validates_format_of :is_analysis_before_type_cast, :with => /[01]/, :message => I18n.t("Must be 1 or 0")
  #
  # ...must *not* be used together with inline_edit = true, because ActiveScaffold has an internal conversion
  # mechanism which acts differently.
  #--


  SQL_DATETIME_FORMAT = "%Y-%m-%d %H:%M"


  # [20121121] Note: "joins" implies an INNER JOIN, whereas "includes", which is used for eager loading of associations,
  # implies a LEFT OUTER JOIN.
  scope :sort_schedule_by_patient,  lambda { |dir| joins(:patient).includes(:patient).order("patients.surname #{dir.to_s}, patients.name #{dir.to_s}") }


  #--
  # ---------------------------------------------------------------------------
  # Base methods:
  # ---------------------------------------------------------------------------
  #++


  # Computes a shorter description for the name associated with this data
  def get_full_name
    if self.patient_id.nil? || (self.patient_id == 0)
      get_date_schedule()
    else
      self.patient.get_full_name
    end
  end

  # Computes a verbose or formal description for the name associated with this data
  def get_verbose_name
    v = get_date_schedule() + ' ' + get_verb_description()
    v = v + self.patient.get_full_name unless self.patient_id.nil? || (self.patient_id == 0)
    v = v + ' ' unless self.notes.blank? || self.patient_id.nil? || self.patient_id == 0
    v = v + self.notes unless self.notes.blank?
    v
  end

  # Computes a displayable string representing the required date_schedule field.
  def get_date_schedule
    unless date_schedule.blank?
      Format.a_short_datetime( date_schedule )
    else
      ''
    end
  end

  # Computes just the verb description for this data
  def get_verb_description()
    v = (self.must_insert? ? I18n.t(:must_insert, :scope => [:schedule]).upcase : '')
    v = v + "/ " if (v != "") and self.must_move?
    v = v + ( (self.must_move?) ? I18n.t(:must_move, :scope => [:schedule]).upcase : '' )
    v = v + "/ " if (v != "") and self.must_call? and (self.must_move? or self.must_insert?)
    v = v + ( (self.must_call?) ? I18n.t(:must_call, :scope => [:schedule]).upcase : '' )
    v
  end

  # Computes a full description for this data
  def get_full_description( use_HTML = true )
    d = (use_HTML && self.is_done? ? '<s>' : '') +
        self.get_verb_description() +
        (use_HTML ? '<b> ' : ' ') +
        self.get_full_name +
        (use_HTML ? '</b> ' : ' ') +
        (self.notes.blank? ? '' : self.notes) +
        (use_HTML && self.is_done? ? '</s>' : '')
    d
  end
  #----------------------------------------------------------------------------
  #++


  # Checks and sets fields value defaults.
  #
  # === Parameters:
  # - +params_hash+ => Hash of additional parameter values for attribute defaults override.
  #
  def preset_default_values( params_hash = {} )
    unless self.patient                             # Set current patient only if not set
      begin
        if params_hash[:patient_id]
          self.patient_id = params_hash[:patient_id].to_i
        end
      rescue
        self.patient_id = nil
      end
    end

    unless self.date_schedule                       # A default date schedule must be set anyhow:
      begin                   
          self.date_schedule = params_hash[:date_schedule] ? params_hash[:date_schedule] : Time.now
      rescue                                        # Set default date for this entry:
        self.date_schedule = Time.now
      end
    end
    self
  end
  # ----------------------------------------------------------------------------


  # Returns the (short) verbose name for the corresponding month number (1..12).
  def Schedule.short_month_name( month_number )
    I18n.t( :abbr_month_names, :scope => [:date] )[ month_number ]
  end

  # Returns the (long) verbose name for the corresponding month number (1..12).
  def Schedule.long_month_name( month_number )
    I18n.t( :month_names, :scope => [:date] )[ month_number ]
  end

  # Returns the (short) verbose name for the corresponding commercial week-day
  # number (1=Monday..6=Saturday, 0=Sunday).
  def Schedule.short_day_name( cwday_number )
    I18n.t( :abbr_day_names, :scope => [:date] )[ cwday_number ]
  end

  # Returns the (long) verbose name for the corresponding commercial week-day
  # number (1=Monday..6=Saturday, 0=Sunday).
  def Schedule.long_day_name( cwday_number )
    I18n.t( :day_names, :scope => [:date] )[ cwday_number ]
  end
  # ---------------------------------------------------------------------------


  # Computes a given date-time coordinate using the two separate date and
  # time components.
  # The result is a parsable DateTime string representation
  # usable for a WHERE clause in MySQL default DateTime format.
  #
  # at_date : a Date instance representing the day coordinate
  # at_time : a DateTime instance representing the time coordinate
  def Schedule.format_datetime_coordinates_for_mysql_param( at_date, at_time )
    "#{at_date.year.to_s}-" << "%02u" % at_date.month.to_s << "-" << "%02u" % at_date.day.to_s << " " <<
        "%02u" % at_time.hour.to_s << ":" << "%02u" % at_time.min.to_s
  end

  # Formats a given date-time instance to obtain a parsable DateTime string
  # representation for a WHERE clause in MySQL default DateTime format.
  # a_datetime : a DateTime instance representing the date-time coordinate
  def Schedule.format_datetime_for_mysql_param( a_datetime )
    a_datetime.strftime( SQL_DATETIME_FORMAT )
  end
  # ---------------------------------------------------------------------------


  # Computes the starting date of a week.
  #
  # a_date : a Date instance representing the day coordinate
  def Schedule.get_week_start( a_date = Date.today )
    a_date = Date.today if a_date.nil?
    a_date - a_date.cwday + 1                       # Go to the beginning of the week
  end

  # Computes the ending date of week, returning a parsable DateTime string
  # usable in a WHERE clause (in MySQL default DateTime format).
  #
  # a_date : a Date instance representing the day coordinate
  def Schedule.get_week_end( a_date = Date.today )
    a_date = Date.today if a_date.nil?
    a_date - a_date.cwday + 6                       # Go to the beginning, then to the end of week
  end

  # Computes the total number of weeks of a specified date range, returning an
  # array of couples of Date instances, having the size of the number of weeks found,
  # with each couple of Date instance representing the first and the last day of each
  # computed week.
  #
  # This is used to extract date-point coordinates from date ranges in time-lapse charts.
  #
  # from_date : the starting Date instance of the range
  # to_date   : the ending Date instance of the range
  def Schedule.get_all_week_ends_for_range( from_date, to_date )
    from_date = Date.parse( from_date ) if from_date.instance_of?( String )
    to_date   = Date.parse( to_date ) if to_date.instance_of?( String )
    raise "Schedule.get_all_week_ends_for_range(): parameters are not valid date instances!" unless ( from_date.instance_of?(Date) && to_date.instance_of?(Date) )

    from_date = from_date - from_date.cwday
    to_date   = to_date - to_date.cwday + 7
    tot_weeks = 1 + ( to_date - from_date ).to_i / 7
    result_array = []
                                           # start of the week date (sun)         end date (sat)
    tot_weeks.times { |i| result_array << [ (from_date - from_date.cwday + 7*i), (from_date - from_date.cwday + 6 + 7*i) ] }
    result_array
  end

  # Computes the starting date of a week, returning a parsable DateTime string
  # usable in a WHERE clause (in MySQL default DateTime format).
  #
  # a_date : a Date instance representing the day coordinate
  def Schedule.get_week_start_for_mysql_param( a_date = Date.today )
    a_date = Schedule.get_week_start( a_date )
    "#{ a_date.year.to_s }-" << "%02u" % a_date.month.to_s << "-" << "%02u" % a_date.day.to_s << " 00:00"
  end

  # Computes the ending date of week, returning a parsable DateTime string
  # usable in a WHERE clause (in MySQL default DateTime format).
  #
  # a_date : a Date instance representing the day coordinate
  def Schedule.get_week_end_for_mysql_param( a_date = Date.today )
    a_date = Schedule.get_week_end( a_date )
    "#{ a_date.year.to_s }-" << "%02u" % a_date.month.to_s << "-" << "%02u" % a_date.day.to_s << " 23:59"
  end
  # ---------------------------------------------------------------------------


  # Retrieves all schedules for the week of a specified date.
  #
  # a_date : a Date instance selecting the week to be processed.
  # exclude_is_done : filter value on is_done (not nil => exclude all where is_done == 1; nil => don't care, do not filter)
  def Schedule.find_all_week_schedules( a_date = Date.today, exclude_is_done = nil )
    if exclude_is_done.nil?
      conditions_array = [ '(date_schedule >= ? and date_schedule <= ?)', 
                           Schedule.get_week_start_for_mysql_param( a_date - 7 ), 
                           Schedule.get_week_end_for_mysql_param( a_date + 7 ) ]
    else
      conditions_array = [ '(date_schedule >= ? and date_schedule <= ?) and (is_done <> 1)', 
                           Schedule.get_week_start_for_mysql_param( a_date - 7 ), 
                           Schedule.get_week_end_for_mysql_param( a_date + 7 ) ]
    end
    Schedule.find( :all, :conditions => conditions_array )
  end
  # ---------------------------------------------------------------------------



  protected


  def validate
                                                    # ActiveScaffold will automatically invoke localization on these texts:
    errors.add( I18n.t(:date_schedule, :scope=>[:schedule]), 'nothing was selected!' ) if date_schedule.nil?
    errors.add( I18n.t(:patient, :scope=>[:patient]), 'nothing was selected!' ) if patient.nil? || patient_id == 0
  end
  #----------------------------------------------------------------------------
end
