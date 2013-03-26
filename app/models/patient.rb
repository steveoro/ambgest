require 'common/format'


class Patient < ActiveRecord::Base

  belongs_to :le_title
  belongs_to :le_city

  has_many :appointments

  validates_associated :le_title
  validates_associated :le_city

  validates_presence_of :name, :message => :can_t_be_blank

  validates_length_of :name, :within => 1..40
  validates_length_of :surname, :within => 1..80
  validates_length_of :address, :maximum => 255, :allow_nil => true

  validates_uniqueness_of :name, :scope => [ :surname, :le_city_id, :address ],
                      :message => :already_exists

  validates_length_of :tax_code, :maximum => 18, :allow_nil => true
  validates_length_of :phone_home, :maximum => 40, :allow_nil => true
  validates_length_of :phone_work, :maximum => 40, :allow_nil => true
  validates_length_of :phone_cell, :maximum => 40, :allow_nil => true
  validates_length_of :phone_fax, :maximum => 40, :allow_nil => true
  validates_length_of :e_mail, :maximum => 100, :allow_nil => true
  validates_length_of :notes, :maximum => 255, :allow_nil => true
  validates_length_of :default_invoice_text, :maximum => 120, :allow_nil => true

  validates_numericality_of :default_invoice_price
  validates_numericality_of :appointment_freq

  validates_length_of :preferred_days, :maximum => 255, :allow_nil => true
  validates_length_of :preferred_times, :maximum => 255, :allow_nil => true

#  validates_format_of :specify_neurologic_checkup_before_type_cast, :with => /[01]/, :message => as_('must be 0 or 1')
#  validates_format_of :is_suspended_before_type_cast, :with => /[01]/, :message => as_('must be 0 or 1')
#  validates_format_of :is_a_firm_before_type_cast, :with => /[01]/, :message => as_('must be 0 or 1')
#  validates_format_of :is_fiscal_before_type_cast, :with => /[01]/, :message => as_('must be 0 or 1')
  # ---------------------------------------------------------------------------
  # Note: boolean validation via a typical...
  #
  #   validates_format_of :is_analysis_before_type_cast, :with => /[01]/, :message => as_("Must be 1 or 0")
  #
  # ...must *not* be used together with inline_edit = true, because ActiveScaffold has an internal conversion
  # mechanism which acts differently.


  # [20121121] About pre-defined scopes in Model class and Drop-down Combo-boxes:
  # For the combo-boxes to have a working query after the 4th char is entered in the edit widget,
  # a lambda statement must be used. Using a pre-computed scope from the Model class prevents Netzke
  # (as of this version) to append the correct WHERE clause to the scope itself (with an inline
  # lambda, instead, it works).
  # So, any scope defined here should be used only for controller-related logic and not inside
  # any Netzke component combo-boxes.
  scope :still_available, where(:is_suspended => false).order("surname ASC, name ASC")


  #----------------------------------------------------------------------------
  # Base methods:
  #----------------------------------------------------------------------------
  #++


  # Computes a shorter description for the name associated with this data
  def get_full_name
    [
      (surname.empty? ? nil : surname),
      (name.empty? ? nil : name)
    ].compact.join(" ")
  end

  # Computes a verbose or formal description for the name associated with this data
  def get_verbose_name
    [
      (self.le_title.nil? ? nil : self.le_title.name),
      get_full_name
    ].compact.join(" ")
  end


  # Computes a shorter description for the address associated with this data
  def get_full_address
    [
      (address.empty? ? nil : address),
      (self.le_city.nil? ? nil : self.le_city.get_full_name)
    ].compact.join(", ")
  end

  # Computes a verbose or formal description for the address associated with this data
  def get_verbose_address
    [
      (address.empty? ? nil : address),
      (self.le_city.nil? ? nil : self.le_city.get_verbose_name)
    ].compact.join(", ")
  end

  # Retrieves the default description to be used for the main data row of the Receipt
  # associated with this instance data.
  #
  def get_default_receipt_description()
    if ( is_a_firm? )
      sprintf(
          I18n.t(:firm_receipt_description),
          date_receipt.strftime("%B").t + ' ' + date_receipt.strftime("%Y")
      )
    else
      if ( specify_neurologic_checkup? )
        I18n.t(:alternate_receipt_description)
      else
        I18n.t(:default_receipt_description)
      end
    end
  end
  #----------------------------------------------------------------------------
  #++


  # "Valid" entity row collection getter.
  def Patient.get_collection_of_appointment_freq()
    [
      [I18n.t(:occasional, :scope => [:patient]), 0],
      [I18n.t(:weekly, :scope => [:patient]), 7],
      [I18n.t(:twice_a_month, :scope => [:patient]), 15],
      [I18n.t(:monthly, :scope => [:patient]), 30]
    ]
  end
  # ---------------------------------------------------------------------------


  # Retrieves all active and selectable Patient instances.
  # If +include_this_id+ is > 0, the specified Patient id will also be included.
  #
  def Patient.get_options_for_select( include_this_id = 0 )
    begin
      patients_found = Patient.find(
                          :all,
                          :conditions => (include_this_id.nil? || include_this_id < 1) ?
                                         '(is_suspended = 0)' :
                                         ['(is_suspended = 0) or (id = ?)', include_this_id],
                          :order => 'surname ASC, name ASC'
      ).collect {|p| [ p.get_full_name, p.id ] }
    rescue
      $stderr.print "*[E]* Patient.get_options_for_select() failed:\r\n " + $!
    end
    return patients_found || []
  end
  # ---------------------------------------------------------------------------


  # Retrieves a subset of Patient ids given the likeliness with a full patient name.
  def Patient.get_ids_by_name( full_name )
    ids_found = []
    begin
      if full_name
        patients_found = Patient.find_by_sql( ["SELECT * FROM patients WHERE " +
                                               "(concat(surname,\" \",name) like ?)" +
                                               " ORDER BY surname ASC",
                                               full_name] )
      else
        patients_found = Patient.find( :all )
      end
      patients_found.each { |c| (ids_found << c.id) }
    rescue
      $stderr.print "*[E]* Patient.get_ids_by_name(#{full_name}) failed:\r\n " + $!
    end
    return ids_found
  end
  # ---------------------------------------------------------------------------
  #++

  # Checks and sets unset fields to default values.
  #
  # === Parameters:
  # - +params_hash+ => Hash of additional parameter values for attribute defaults override.
  #
  def preset_default_values( params_hash = {} )
    # XXX AmbGest 1.10 does not have a Firm entity:
#    unless self.firm
#      begin
#        if self.user_id and (default_firm_id = LeUser.find(self.user_id).firm_id)
#          self.firm_id = default_firm_id
#        end
#      rescue
#        self.firm_id = nil
#      end
#    end
                                                    # Set default date for this entry:
#    self.date_last_met = Time.now unless self.date_last_met
    self
  end
  # ---------------------------------------------------------------------------


  # ---------------------------------------------------------------------------
  # Grouping / Data Export / Summary / Reporting interface implementations:
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
      :name, :surname, :address, :le_city,
      :tax_code,
      :phone_home, :phone_work, :phone_cell, :phone_fax, :e_mail
    ]
  end
  # ---------------------------------------------------------------------------
  #--


  # ---------------------------------------------------------------------------
  # ActiveScaffold custom action authorization overrides:
  # ---------------------------------------------------------------------------
  #++


  # Returns true if a new "multi-appointment" Receipt can be issued for the current Patient instance.
  # This is possible only if the current patient has any "free", not-yet-invoiced, appointments.
  # 
  def multi_appointment_receipt_allowed?()          # We must validate record existance (for AS security layer):
    return false unless existing_record_check?      # (current record instance could be empty or new)
                                                    # Existing records must be checked for this also:
    ( Appointment.find_all_unpayed_for_patient( self.id ).size > 0 )
  end


  # Custom security check for the custom :issue_receipt action.
  #
  def authorized_for?(*args)
    return false if current_user.nil?               # If current_user is not defined or the model is accessed outside of the request/response cycle, bail out
    is_allowed = current_user.can_do( :appointments, args[0][:action] )

    return is_allowed && multi_appointment_receipt_allowed? if args[0][:column].blank? && (args[0][:action] == :issue_receipt)
    return is_allowed
  end
  # ---------------------------------------------------------------------------


  protected


  def validate
                                                    # Globalize will automatically invoke localization on these texts:
    errors.add( :default_invoice_price, 'It should be at least 0.01' ) if default_invoice_price.nil? || default_invoice_price < 0.01
  end
  # ---------------------------------------------------------------------------
end
