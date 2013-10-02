# encoding: utf-8

require 'ruport'
require 'ruport/data/table'

require 'common/format'
require 'framework/interface_data_export'


class Receipt < ActiveRecord::Base
  include InterfaceDataExport

  belongs_to :patient
  has_many :appointments

  validates_associated :patient

  validates_presence_of :date_receipt
  validates_presence_of :patient_id

  validates_numericality_of :price
  validates_numericality_of :receipt_num, :greater_than => 0

  validates_length_of :receipt_description, :maximum => 120, :allow_nil => true
  validates_length_of :notes, :maximum => 255, :allow_nil => true
  validates_length_of :additional_notes, :maximum => 255, :allow_nil => true

#  validates_format_of :is_receipt_delivered_before_type_cast, :with => /[01]/, :message => I18n.t("Must be 1 or 0")
#  validates_format_of :is_payed_before_type_cast, :with => /[01]/, :message => I18n.t("Must be 1 or 0")
  #--
  # Note: boolean validation via a typical...
  #
  #   validates_format_of :is_receipt_delivered_before_type_cast, :with => /[01]/, :message=> :must_be_0_or_1
  #
  # ...must *not* be used since the ExtJS grids convert internally the values from string/JSON text.


  after_save :update_associated_appointments


  # [20121121] Note: "joins" implies an INNER JOIN, whereas "includes", which is used for eager loading of associations,
  # implies a LEFT OUTER JOIN.
  scope :sort_receipt_by_patient,       lambda { |dir| joins(:patient).includes(:patient).order("patients.surname #{dir.to_s}, patients.name #{dir.to_s}") }
  scope :sort_receipt_by_receipt_code,  lambda { |dir| order("DATE_FORMAT(date_receipt,'%Y') #{dir.to_s}, receipt_num #{dir.to_s}") }


  #-----------------------------------------------------------------------------
  # Base methods:
  #-----------------------------------------------------------------------------
  #++


  # Computes a shorter description for the name associated with this data
  def get_full_name
    get_receipt_code()
  end

  # Computes a verbose or formal description for the name associated with this data
  def get_verbose_name
    if self.patient_id.nil? || (self.patient_id == 0)
      get_receipt_header()
    else
      self.patient.get_full_name.upcase + '  ' + get_receipt_header()
    end
  end

  # Retrieves an array of title string names that can be used for both
  # report titles (and subtitles) or as base names of any output file created
  # with the data associated with this row instance.
  #
  # The array contains any header description characterizing this row instances,
  # in the form:
  #     [ header_description_1, header_description_2, ... ]
  #
  # I can be easily rendered with [].join(" - ") for being drawn on a single line.
  # The purpose of this method is obviously to obtain a verbose unique 'title'
  # identifier which best describes the whole dataset this row belongs to.
  #
  def get_title_names( title_sym = :receipt )
    [
      I18n.t( title_sym.nil? ? :receipt : title_sym.to_sym, {:scope=>[:receipt]}),
      get_year_with_number(),
      self.patient.surname
    ]
  end

  # Uses +get_title_names+() to obtain a single string name usable as
  # base file name for many output reports or data exchange files created while removing
  # special chars that may conflict with legacy filesystems.
  #
  def get_base_name( title_sym = :receipt )
    get_title_names( title_sym ).join("_").gsub(/[òàèùçé^!"'£$%&?.,;:§°<>]/,'').gsub(/[\s|]/,'_').gsub(/[\\\/=]/,'-')
  end
   # ---------------------------------------------------------------------------
  #++

  # Computes a displayable string representing the date_receipt field.
  def get_date_receipt
    unless date_receipt.blank?
      Format.a_short_datetime( date_receipt )
    else
      ''
    end
  end

  # Computes a displayable string representing a terse header of the receipt.
  def get_receipt_code
    if self.receipt_num > 0
      Receipt.check_date_receipt_is_not_nil( id, receipt_num, date_receipt )
      Receipt.format_receipt_code( receipt_num, date_receipt )
    else
      ''
    end
  end

  # Computes a displayable and sortable string representing the header of the receipt.
  def get_receipt_sortable_code
    if self.receipt_num > 0
      Receipt.check_date_receipt_is_not_nil( id, receipt_num, date_receipt )
      "#{ date_receipt.strftime("%Y") }#{ sprintf("%03i", receipt_num) }"
    else
      ''
    end
  end

  # Computes a displayable string representing a terse header of the receipt.
  def get_receipt_header
    if self.receipt_num > 0
      Receipt.check_date_receipt_is_not_nil( id, receipt_num, date_receipt )
      Receipt.format_receipt_header( receipt_num, date_receipt, self.patient.nil? ? nil : self.patient.get_full_name.upcase )
    else
      ''
    end
  end

  # Returns a formatted text representing the receipt number and its date,
  # assuming both contain valid values (a number and a date instance).
  def Receipt.format_receipt_code( receipt_num, date_receipt )
      "# #{ receipt_num.to_s } / #{ date_receipt.strftime("%Y") }"
  end

  # Returns a more "verbose" version of format_receipt_code().
  def Receipt.format_receipt_header( receipt_num, date_receipt, patient_name = nil )
      "# #{ receipt_num.to_s }, #{ date_receipt.strftime("%d-%m-%Y") }" << (patient_name.nil? ? '' : " - #{patient_name}")
  end
  # ---------------------------------------------------------------------------

  # Retrieves the default description to be used for the main data row of the Receipt
  # associated with this instance data.
  #
  # Since application version 2, this supports localization via config/locales YML files
  # and does not make use anymore of specific database-stored values.
  #
  # +record+ must be an instance of either Appointment or Receipt (both can act as receipt headers,
  # with some limitations).
  #
  def Receipt.get_default_receipt_description( record )
    receipt_num   = record.receipt_num.to_i
    date_receipt  = record.instance_of?(Receipt) ? record.date_receipt : Time.now
    id            = record.instance_of?(Receipt) ? record.id : record.receipt_id
    receipt_description = record.instance_of?(Receipt) ? record.receipt_description : nil

                                                    # If it's not a new, unsaved record, we can check also this:
    unless record.nil? || record.new_record?
      Receipt.check_date_receipt_is_not_nil( id, receipt_num, date_receipt )
    else
      date_receipt = Time.now if date_receipt.nil?  # Make really sure date_receipt is never nil
    end
                                                    # Override value present?
    return receipt_description unless receipt_description.nil?
                                                    # Check normal cases:
    if ( record.patient )
      record.patient.get_default_receipt_description()
    end
  end


  # Virtual attribute for row quantity (fixed to 1).
  def qty()
    1
  end

  # Virtual attribute for row description.
  def description()
    Receipt.get_default_receipt_description( self )
  end

  # Virtual attribute for row percent (fixed to a blank string).
  def percent()
    ''
  end

  # Virtual getter for currency symbol
  def get_currency_symbol
    "€"
  end

  # Virtual getter for currency name
  def get_currency_name
    "euro"
  end


  # Computes the full (printable) receipt notes taking into account both members
  # 'is_payed' and 'additional_notes'.
  #
  def get_receipt_notes
    result = ''
    result << self.additional_notes unless self.additional_notes.blank?
    result << "\n\n" if self.additional_notes && self.is_payed?
    result << I18n.t(:payed, {:scope=>[:receipt]}).upcase if self.is_payed?
    result
  end


  # Returns the float value of the net price for this Appointment instance.
  #
  # From the starting price, (checking get_additional_cost_totals()) only the :negative items to be divested are taken out
  # of the sum resulting in the total net amount.
  #
  def net_price
    if self.patient.is_a_firm?
      self.price
    else
      self.price + get_additional_cost_totals()[:negative]
    end
  end
  alias_method :amount, :net_price


  # Returns the float value of the total account_percent cost computed
  # on the price member of this instance value.
  #
  def account_percentage_amount( acc_percent = nil )
    tot_cost = 0.0              # init result
    if self.patient.is_a_firm?
      acc_percent ||= AppParameter.get_receipt_account_percent()
      tot_cost += self.price * acc_percent.to_f / 100.0
    end
    return tot_cost
  end
  # ---------------------------------------------------------------------------


  # Returns an hash of positive and negative float totals computed on the hash of
  # additional costs of this Appointment instance.
  #
  # FIXME [201003010] REFACTOR THIS:
  # The additional receipt costs are supposed to be all percentages.
  #
  # :positive : the (float) total amount of positive costs found
  # :negative : the (float) total amount of positive costs found
  #
  def get_additional_cost_totals
    pos_cost = 0.0              # init result
    neg_cost = 0.0              # init result
    AppParameterCustomizations.get_receipt_costs().each do |c|
      if c[:value] > 0
        pos_cost += c[:value].to_f / 100.0
      elsif self.price >= 78.19
        neg_cost += c[:value].to_f / 100.0 unless self.patient.is_a_firm?
      end
    end
    return { :negative => neg_cost, :positive => pos_cost }
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
    unless self.receipt_description
      if (self.patient_id.to_i > 0) && (p = Patient.find(self.patient_id))
        self.price = p.default_invoice_price unless (self.price.to_f > 0.0)
        self.receipt_description = p.default_invoice_text if self.receipt_description.blank? && (! p.default_invoice_text.blank?)
      end
                                                    # Set the default description if not yet set:
      self.receipt_description = Receipt.get_default_receipt_description(self) unless self.receipt_description
    end

    unless self.date_receipt                        # A default date_receipt must be set anyhow:
      begin                   
          self.date_receipt = params_hash[:date_receipt] ? params_hash[:date_receipt] : Time.now
      rescue                                        # Set default date for this entry:
        self.date_receipt = Time.now
      end
    end

    self.receipt_num = Receipt.get_next_receipt_num() unless (self.receipt_num > 0)
    self.is_receipt_delivered ||= 0
    # [Steve, 20100915] Known issue: we cannot set automatically or directly the "is_payed" flag (for instance,
    # reading the corresponding flag on any issuing appointment row) since this acts as a global "is_payed" status
    # for the whole due amount and - also - there may be more than 1 appointment rows linked to this receipt
    # (and the patient could be paying just a partial sum on each appointment).
    # So this needs to be cleared on start, until the whole receipt has been effectively "payed" (the user toggles it).
    self.is_payed ||= 0
    self
  end
  # ----------------------------------------------------------------------------


  # ---------------------------------------------------------------------------
  # Grouping / Data Export / Summary / Reporting interface implementations:
  # ---------------------------------------------------------------------------
  #++


  # FIXME STILL both used?

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


  # FIXME STILL used?

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
    [ :date_receipt, :receipt_num, :patient, :price, :receipt_description ]
  end


  # Returns the list of "header" +Hash+ keys (the +Array+ of +Symbols+) that will be used to create the result
  # of <tt>prepare_report_header_hash()</tt> and that will also be added to the list of all possible (localized)
  # "labels" returned by <tt>self.get_label_hash()</tt>.
  #
  # The returned symbols are supposed to be all the keys of <tt>prepare_report_header_hash()</tt>
  #
  def self.report_header_symbols()
    [
      :title, :date_receipt, :customer_name, :customer_info, :customer_tax_code,
      :customer_tax_code_label, :customer_notes, :customer_signature, :copy_watermark
    ]
  end

  # Returns the list of the "detail" key +Symbols+ that will be used to create the result
  # of <tt>prepare_report_detail()</tt> and that will also be added to the list of all possible (localized)
  # "labels" returned by <tt>self.get_label_hash()</tt>.
  #
  def self.report_detail_symbols()
    [ :qty, :description, :percent, :amount ]
  end

  # Prepares and returns the result hash containing the header data fields specified
  # in the <tt>report_header_symbols()</tt> list.
  #
  def prepare_report_header_hash( title_sym = :receipt )
    title_text = I18n.t( title_sym.nil? ? :receipt : title_sym.to_sym, {:scope=>[:receipt]})
    {
      :title                  => "#{title_text.upcase} #{get_receipt_code()}",
      :date_receipt           => ( "#{I18n.t(:date_receipt, {:scope=>[:receipt]})}: " + (date_receipt.blank? ? '' : Format.a_date( date_receipt )) ),
      :customer_name          => ( self.patient ? self.patient.get_verbose_name : '' ),
      :customer_info          => ( self.patient ? self.patient.get_full_address : '' ),
      :customer_tax_code      => ( self.patient ? self.patient.tax_code.to_s    : '' ),
      :customer_tax_code_label=> ( self.patient ? I18n.t(self.patient.is_a_firm? ? :vat_registration : :tax_code) : '' ),
      :customer_notes         => get_receipt_notes(),
      :customer_signature     => I18n.t(:customer_signature, {:scope=>[:receipt]}),
      :copy_watermark         => I18n.t(:copy_watermark, {:scope=>[:invoice_row]})
    }
  end


  # Returns a Ruport::Data::Table containing a summarized report detail for the current instance
  # data.
  # This method is used in building the Receipt PDF layout.
  #
  def prepare_report_detail()
    Ruport::Data::Table.new( :column_names => self.class.report_detail_symbols() ) { |t|
    t << self.to_a_s( self.class.report_detail_symbols(), CONVERTED_FLOAT2STRING_FIXED_PRECISION, 8 )
      percentage_amount = 0.0
      if self.patient && self.patient.is_a_firm? && self.patient.is_fiscal?
        account_percent = AppParameterCustomizations.get_receipt_account_percent()
        percentage_amount = self.account_percentage_amount( account_percent )
        t << ['',
              I18n.t(:vat_withholding),
              "#{Format.float_value( account_percent, 0, CONVERTED_PERCENT2STRING_FIXED_LENGTH )} %",
              Format.float_value( percentage_amount, 2, CONVERTED_FLOAT2STRING_FIXED_LENGTH )
        ]
      end
      costs = self.get_additional_cost_totals()
      total_amount = (self.net_price() + percentage_amount + costs[:positive] - costs[:negative])
      t << ['',
            '',
            "<i>#{I18n.t(:to_be_payed, {:scope=>[:receipt]})}:</i>",
            "<b>#{Format.float_value( total_amount, 2, CONVERTED_FLOAT2STRING_FIXED_LENGTH )}</b>"
      ]
    }
  end
  # ----------------------------------------------------------------------------


  # ----------------------------------------------------------------------------
  # Custom finders
  # ----------------------------------------------------------------------------


  # Retrieves all receipts issued for a specified date range.
  #
  # sql_string_date_from, sql_string_date_to : string dates already-sanitized for SQL representing the range.
  #
  def self.find_all_receipts_for( sql_string_date_from, sql_string_date_to )
    Receipt.find_rows_by_conditions( ['(date_receipt >= ? and date_receipt <= ?)', sql_string_date_from, sql_string_date_to ] )
  end
  # ---------------------------------------------------------------------------

  # Computes a displayable numeric description of the invoice, using its number and the year in four digits.
  # (e.g.: "4 / 2007")
  #
  def get_number_with_year
    receipt_num.to_s + " / " + get_date_receipt().strftime("%Y")
  end

  # The opposite of +get_year_with_number+, but prefixing also the number with leading zeroes.
  # Perfectly suitable for filenames (e.g.: "2007-0004")
  #
  def get_year_with_number
    date_receipt.strftime("%Y") + "-" + sprintf( "%03i", receipt_num )
  end
  # ----------------------------------------------------------------------------


  # Retrieves the latest receipt row for a specified year.
  # 
  # year : Year of the receipt register, to be used in the search.
  #
  def Receipt.find_last_for_the_year( year = Date.today.year )
    Receipt.find_by_sql( ["SELECT *, receipt_num + 1 AS next_num " +
                          "FROM receipts " +
                          "HAVING YEAR(date_receipt) = ?" +
                          " ORDER BY receipt_num DESC LIMIT 1", year] )[0]
  end


  # Retrieves the latest and computes the next assignable receipt number
  # for the specified year.
  # 
  # year : Year of the receipt register, to be used in the search.
  #
  def Receipt.get_next_receipt_num( year = Date.today.year )
    a = Receipt.find_last_for_the_year( year )
    if a.nil?
      num = 1                   # First default receipt number, in case none was found
    else
      num = a.next_num
    end
    return num                  # Return the first element of the array only
  end
  # ---------------------------------------------------------------------------

  # Retrieves all the receipts emitted during the week of a specified date.
  #
  # a_date : a Date instance selecting the week to be processed.
  #
  def Receipt.find_all_week_receipts( a_date )
    Receipt.includes( :patient ).joins( :patient ).find_rows_by_conditions(
        ['(date_receipt >= ? and date_receipt <= ?)', 
         Schedule.get_week_start_for_mysql_param( a_date ), 
         Schedule.get_week_end_for_mysql_param( a_date )]
    )
  end

  # Retrieves all the receipts emitted during a specified date interval.
  #
  # from_date : starting Date instance selecting the interval to be processed.
  # to_date : ending Date instance selecting the interval to be processed.
  #
  def Receipt.find_all_receipts_for( from_date, to_date )
    Receipt.includes( :patient ).joins( :patient ).find_rows_by_conditions(
        [ '(date_receipt >= ? and date_receipt <= ?)', from_date, to_date ]
    )
  end
  # ---------------------------------------------------------------------------


  protected


  # After save, updates any related field inside associated appointments.
  # (for instance, if receipt.is_payed? => all appointments are assumed to be is_payed)
  #
  def update_associated_appointments()
    if self.is_payed?                               # When the receipt is flagged as 'payed', make sure all appointments are too:
      # [Steve, 20100501] The added check on the structure of Appointments is
      # needed to be compliant with the previous version of the structure of the
      # table, otherwise the migration from older DB version fails.
      Appointment.update_all( "is_payed=1", ['receipt_id = ?', self.id] ) if Appointment.new.attributes.include?('receipt_id')
    end
  end
  # ---------------------------------------------------------------------------


  # Retrieves all Receipt rows satisfying the specified condition array.
  #
  def self.find_rows_by_conditions( conditions_array )
    Receipt.find( :all, :conditions => conditions_array )
  end
  # ---------------------------------------------------------------------------


  def check_existance_of_same_date_receipt
    if self.date_receipt                            # Avoid same year(date) and number for different row instances:
      if self.id.to_i > 0                           # It's an update? Check existing records except this one:
        conditions_array = ['(YEAR(date_receipt) = ?) and (receipt_num = ?) and (id <> ?)', self.date_receipt.year, self.receipt_num, self.id]
      else                                          # It's a create? Check any existing records:
        conditions_array = ['(YEAR(date_receipt) = ?) and (receipt_num = ?)', self.date_receipt.year, self.receipt_num]
      end
      errors.add( :receipt_num, 'a receipt with this number exists already in the same year!' ) if Receipt.find( :first, :conditions => conditions_array )
    end
  end


  # Raises an exception if the date receipt is found nil for any row in which
  # the receipt has its number > 0.
  #
  def self.check_date_receipt_is_not_nil( id, receipt_num, date_receipt )
    raise "Data inconsistency found: Date Receipt is nil for Receipt num.#{receipt_num}! (Receipt ID: #{id})" if receipt_num.to_i > 0 && date_receipt.nil?
  end


  def validate                                      # Globalize will automatically invoke localization on these texts:
    errors.add( :receipt_num, "is not specified!" ) if receipt_num.to_i < 1
    errors.add( :date_receipt, "is not specified!" ) if date_receipt.nil?
    errors.add( :patient, 'nothing was selected!' ) if patient.nil? || patient_id == 0
    errors.add( :price, 'it should be at least 0.01' ) if price.nil? || price < 0.01
    check_existance_of_same_date_receipt()
  end
  #----------------------------------------------------------------------------
end
#------------------------------------------------------------------------------
