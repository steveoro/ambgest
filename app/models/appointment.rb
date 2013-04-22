require 'common/format'


class Appointment <  ActiveRecord::Base

  belongs_to :patient
  belongs_to :receipt

  validates_associated :patient
  validates_associated :receipt

  validates_presence_of :date_schedule
  validates_presence_of :patient_id

  validates_numericality_of :price

  validates_length_of :receipt_description, :maximum => 120, :allow_nil => true
  validates_length_of :notes, :maximum => 255, :allow_nil => true
  validates_length_of :additional_notes, :maximum => 255, :allow_nil => true

  #--
  # Note: boolean validation via a typical...
  #
  #   validates_format_of :is_payed_before_type_cast, :with => /[01]/, :message=> :must_be_0_or_1
  #
  # ...must *not* be used since the ExtJS grids convert internally the values from string/JSON text.


  after_save :update_associated_receipts


  # [20121121] Note: "joins" implies an INNER JOIN, whereas "includes", which is used for eager loading of associations,
  # implies a LEFT OUTER JOIN.
  scope :sort_appointment_by_patient,               lambda { |dir| joins(:patient).includes(:patient).order("patients.surname #{dir.to_s}, patients.name #{dir.to_s}") }
  scope :sort_appointment_by_receipt_num,           lambda { |dir| includes(:receipt).order("receipts.receipt_num #{dir.to_s}") }
  scope :sort_appointment_by_is_receipt_delivered,  lambda { |dir| includes(:receipt).order("receipts.is_receipt_delivered #{dir.to_s}") }


  #-----------------------------------------------------------------------------
  # Base methods:
  #-----------------------------------------------------------------------------
  #++


  # Computes a shorter description for the name associated with this data
  def get_full_name
    if self.patient_id.nil? || (self.patient_id == 0)
      get_date_schedule()
    else
      self.patient.get_full_name.upcase
    end
  end

  # Computes a verbose or formal description for the name associated with this data
  def get_verbose_name
    if self.patient_id.nil? || (self.patient_id == 0)
      get_date_schedule()
    else
      self.patient.get_full_name.upcase + ' @ ' + get_date_schedule()
    end
  end
  #-----------------------------------------------------------------------------
  #++


  # Computes a displayable string representing the required date_schedule field.
  def get_date_schedule
    unless date_schedule.blank?
      Format.a_short_datetime( date_schedule )
    else
      ''
    end
  end

  # Virtual field getter.
  def date_receipt
    self.receipt.get_date_receipt() if self.receipt
  end

  # Virtual field getter.
  def receipt_description
    self.receipt.receipt_description if self.receipt
  end

  # Virtual field getter.
  def is_receipt_issued
    (self.receipt_id > 0)
  end
  alias_method :is_receipt_issued?, :is_receipt_issued

  # Virtual field getter.
  def is_receipt_delivered
    if self.receipt
      self.receipt.is_receipt_delivered?
    else
      false
    end
  end
  alias_method :is_receipt_delivered?, :is_receipt_delivered

  # Virtual field getter. Returns 0 in case receipt is not issued yet.
  def get_safe_receipt_id
    self.receipt_id.to_i
  end

  # Virtual field getter.
  def receipt_num
    self.receipt.receipt_num if self.receipt
  end

  # Virtual field getter.
  def receipt_code
    self.receipt.get_receipt_code if self.receipt
  end
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------


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
                                                    # If patient is set and price not, get the default price:
    if (self.patient_id.to_i > 0) and (self.price.to_f < 0.01)
      if p = Patient.find_by_id( self.patient_id )
        self.price = p.default_invoice_price
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


  # ---------------------------------------------------------------------------
  # Grouping / Data Export / Summary / Reporting interface implementations:
  # ---------------------------------------------------------------------------


  # Returns the Symbol of the data column to be used for the main grouping "computation result"
  # (or total sum) among the selected rows of this model (subsequently refined by the +grouping_symbol+,
  # if defined).
  #
  def self.grouping_total_symbol()
    :price
  end

  # Returns the text label to be used as a description for the result of groupings between
  # row instances of this entity.
  #
  def self.grouping_label()
    'Total amount for the found rows'
  end
  # ---------------------------------------------------------------------------
  #++

  # Returns a (constant) Array of symbols used as key reference for header fields or column titles.
  # This header can then be used for both printable (PDF, TXT, ODT) and data (OUT, XML, whatever) export
  # file formats.
  #
  # Note that these do not necessarily correspond to actual column names, but they will be nevertheless
  # used as key indexes to process each row of the final data hash sent to the either the layout builders
  # or the data export methods. The contract to assure field existance is delegated to the implementors
  # or the utilizing methods.
  #
  def self.header_symbols()
    [
      :date_schedule, :patient, :price, :notes
    ]
  end
  # ---------------------------------------------------------------------------
  #--


  # ----------------------------------------------------------------------------
  # Custom finders
  # ----------------------------------------------------------------------------
  #++


  # Retrieves an appointment instance for a given date-time coordinate.
  # at_date : a Date instance representing the day coordinate
  # at_time : a DateTime instance representing the time coordinate
  #
  def Appointment.get_by_coordinates( at_date, at_time )
    Appointment.find_by_date_schedule(              # Format search date according to mySQL:
            Schedule.format_datetime_coordinates_for_mysql_param( at_date, at_time )
    )
  end

  # Retrieves all appointments for the week of a specified date.
  #
  # a_date : a Date instance selecting the week to be processed.
  #
  def Appointment.find_all_week_appointments( a_date )
    Appointment.includes( :patient ).joins( :patient ).find_rows_by_conditions(
        ['(date_schedule >= ? and date_schedule <= ?)', 
         Schedule.get_week_start_for_mysql_param( a_date ), 
         Schedule.get_week_end_for_mysql_param( a_date )]
    )
  end

  # Retrieves all appointments that are not tagged as either payed or invoiced for
  # a specified patient ID
  #
  def Appointment.find_all_unpayed_for_patient( patient_id )
    Appointment.find_rows_by_conditions( ['(receipt_id = 0) and (is_payed = 0) and (patient_id = ?)', patient_id] )
  end

  # Retrieves all appointments that belong to a specified receipt ID
  #
  def Appointment.find_all_for_receipt( receipt_id )
    Appointment.find_rows_by_conditions( ['(receipt_id = ?)', receipt_id] )
  end

  # Retrieves all appointments with issued receipts for the week of a specified date.
  #
  # sql_string_date_from, sql_string_date_to : string dates already-sanitized for SQL representing the range.
  #
  def Appointment.find_all_invoiced_for( sql_string_date_from, sql_string_date_to )
    Appointment.find_rows_by_conditions(
        ['(date_schedule >= ? and date_schedule <= ? and receipt_id > 0)', sql_string_date_from, sql_string_date_to ]
    )
  end
  #----------------------------------------------------------------------------
  #--


  # ---------------------------------------------------------------------------
  # ActiveScaffold custom action authorization overrides:
  # ---------------------------------------------------------------------------
  #++


  # Returns true if a new Receipt can be issued and linked to the current appointment
  # instance.
  # 
  def issue_receipt_authorized?()                   # We must validate record existance (for AS security layer):
    return false unless existing_record_check?      # (current record instance could be empty or new)
                                                    # Existing records must be checked for this also:
    (self.receipt_num.to_i < 1) && (! self.is_receipt_issued?)
  end


  # Custom security check for the custom :issue_receipt action.
  #
  def authorized_for?(*args)
    # XXX [Steve, 20100315]
    #
    #     This is required because of the current model-security layer implementation in ActiveScaffold,
    #     which is limited to CRUD action types and only the standard CRUD actions are successfully checked
    #     for their XXX_authorized? methods - unless a 'custom' :crud_type is specified in the
    #     config.action_link.add() statement of the controller.
    #
    #     Moreover, specifying anything beside :create, :read, :update or :delete for this :crud_type
    #     will raise an "unknown CRUD action type" error, _unless_ intercepted here in the
    #     method below. (And this is the reason why :crud_type => :issue_receipt works.)
    #
    #     Specifying anything in the :secury_method parameter of the config.action_link.add() statement
    #     does not solve the issue since the :secury_method is just controller-related and not member (or record) aware.
    #
    #     For instance, the method issue_receipt_authorized?() above is called automatically would this
    #     authorized_for?() implementation be commented out - but, alas, this would spawn the error mentioned
    #     before.
    #
# DEBUG
#    puts "#\r\n--- authorized_for?( #{args.inspect} ) CHECKING => #{current_user.inspect}"
    return false if current_user.nil?               # If current_user is not defined or the model is accessed outside of the request/response cycle, bail out
    is_allowed = current_user.can_do( :appointments, args[0][:action] )
# DEBUG
#    puts "--- is_allowed: #{is_allowed}"

    return is_allowed && issue_receipt_authorized? if args[0][:column].blank? && (args[0][:action] == :issue_receipt)
    return is_allowed && (! is_receipt_issued?) if args[0][:column].blank? && (args[0][:action] == :delete)
    return is_allowed
  end
  # ----------------------------------------------------------------------------
  #++


  protected


  # After save, updates any related field inside the associated receipt row.
  # (for instance, if all appointments are 'is_payed' => the associated receipt is assumed to be 'is_payed')
  #
  def update_associated_receipts()
    if self.is_payed? && self.is_receipt_issued?
      apps_found = Appointment.find( :all, :conditions => ['(receipt_id = ?) and (is_payed <> 1)', self.receipt_id] )
      if apps_found.size == 0                       # If there aren't any other unpayed appointments, make sure the receipt is flagged as 'payed' too:
        Receipt.update( self.receipt_id, :is_payed => 1 )
      end
    end
  end
  # ---------------------------------------------------------------------------


  # Retrieves all Appointment rows satisfying the specified condition array.
  #
  def Appointment.find_rows_by_conditions( conditions_array )
    Appointment.find( :all, :conditions => conditions_array, :order => 'date_schedule', :include => [:patient, :receipt] )
  end
  # ---------------------------------------------------------------------------


  def check_existance_of_same_date_appointment
    if self.date_schedule                           # Avoid same date & time for different appointments
      if self.id.to_i > 0                           # It's an update? Check existing records except this one:
        conditions_array = ['(date_schedule = ?) and (id <> ?)', self.date_schedule, self.id]
      else                                          # It's a create? Check any existing records:
        conditions_array = ['(date_schedule = ?)', self.date_schedule]
      end
      errors.add( :date_schedule, 'an appointment exists already at the same date and time!' ) if Appointment.find( :first, :conditions => conditions_array )
    end
  end


  def validate                                      # Globalize will automatically invoke localization on these texts:
    errors.add( :patient, 'nothing was selected!' ) if patient.nil? || patient_id == 0
    errors.add( :price, 'it should be at least 0.01' ) if price.nil? || price < 0.01
    check_existance_of_same_date_appointment()
  end
  #----------------------------------------------------------------------------
end
#------------------------------------------------------------------------------
