#
# Custom Receipt details Form component implementation
#
# - author: Steve A.
# - vers. : 3.05.05.20131002
#
class AppointmentDetails < Netzke::Basepack::FormPanel

  # Component ID used to uniquely address the Patient combo box
  PATIENT_COMBO_FIELD_CMP_ID  = "form_appointment_patient_get_full_name"

  # Component ID used to uniquely address the Appointment Price edit field
  PRICE_FIELD_CMP_ID          = "form_appointment_price"

  # Component ID used to uniquely address the Appointment "is_payed" bool field
  PAYED_FIELD_CMP_ID          = "form_appointment_is_payed"

  # Component ID used to uniquely address the Appointment "is_receipt_delivered" bool field
  DELIVERED_FIELD_CMP_ID      = "form_appointment_is_receipt_delivered"

  # Component ID used to uniquely address the Appointment "is_receipt_issued" bool field
  ISSUED_FIELD_CMP_ID         = "form_appointment_is_receipt_issued"


  model 'Appointment'

  js_properties(
    :prevent_header => true,
    :header => false,
    :border => false
  )


  def configuration
   super.merge(
      :persistence => true,
      :width => 500
   )
  end


  items [
    {
      :column_width => 1.00, :border => false, :defaults => { :label_width => 120 },
      :items => [

        { :name => :date_schedule,          :field_label => I18n.t(:date_schedule, {:scope=>[:appointment]}), :width => 110,
          :default_value => DateTime.now, :width => 300
        },
        { :name => :patient__get_full_name, :field_label => I18n.t(:patient, {:scope=>[:patient]}), :width => 150,
          :id => PATIENT_COMBO_FIELD_CMP_ID,
          :field_style => 'font-size: 110%; font-weight: bold;', :width => 350,
          # [20121121] For the combo-boxes to have a working query after the 4th char is entered in the edit widget,
          # a lambda statement must be used. Using a pre-computed scope from the Model class prevents Netzke
          # (as of this version) to append the correct WHERE clause to the scope itself (with an inline lambda, instead, it works).
          :scope => lambda { |rel| rel.where(:is_suspended => false).order("surname ASC, name ASC") }
        },
        { :name => :price,                  :field_label => I18n.t(:price, {:scope=>[:appointment]}), :width => 60,
          :id => PRICE_FIELD_CMP_ID, :align => 'right', :format => '0.00', :width => 200
        },
        { :name => :additional_notes,       :field_label => I18n.t(:additional_notes, {:scope=>[:appointment]}),
          :width => 400, :xtype => :textareafield
        },
        { :name => :is_receipt_issued,      :field_label => I18n.t(:is_receipt_issued, {:scope=>[:appointment]}),
          :xtype => :checkboxfield, :renderer => 'renderConvertStringToBool',  :width => 120,
          :id => ISSUED_FIELD_CMP_ID, :read_only => true, :disabled => true
        },
        { :name => :receipt_code,           :field_label => I18n.t(:receipt_num, {:scope=>[:receipt]}),
          :align => 'right', :width => 250, :read_only => true, :disabled => true
        },
        { :name => :is_receipt_delivered,   :field_label => I18n.t(:is_receipt_delivered, {:scope=>[:receipt]}),
          :xtype => :checkboxfield, :renderer => 'renderConvertStringToBool',  :width => 120,
          :id => DELIVERED_FIELD_CMP_ID, :read_only => true, :disabled => true
        },
        { :name => :is_payed,               :field_label => I18n.t(:is_payed, {:scope=>[:appointment]}),
          :id => PAYED_FIELD_CMP_ID, :width => 120, :field_style => 'min-height: 13px; padding-left: 13px;',
          :unchecked_value => 'false'
        },
        { :name => :notes,                  :field_label => I18n.t(:notes), :width => 400,
          :xtype => :textareafield
        }
      ]
    }
  ]

  # ---------------------------------------------------------------------------


  js_method :init_component, <<-JS
    function() {
      #{js_full_class_name}.superclass.initComponent.call(this);

      var cmp = Ext.getCmp( "#{PATIENT_COMBO_FIELD_CMP_ID}" );
      cmp.on( 'change',
        function( comboCmp, newValue, oldValue, eOpts ) {
// DEBUG
//          console.log( 'Changed ID: ' + oldValue + ' => ' + newValue );
          var cmp = Ext.getCmp( "#{ISSUED_FIELD_CMP_ID}" );
          var isNotIssued = ! cmp.getValue();
          cmp = Ext.getCmp( "#{PAYED_FIELD_CMP_ID}" );
          var isNotPayed = ! cmp.getValue();
          cmp = Ext.getCmp( "#{DELIVERED_FIELD_CMP_ID}" );
          var isNotDelivered = ! cmp.getValue();
                                                    // Do the update of the form only when the user changes the data and we can proceed:
          if ( (oldValue != newValue) && isNotIssued &&
               isNotPayed && isNotDelivered )
            this.findPatientDefaults({ 'id': newValue });
        },
        this
      );
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------


  js_method :after_find_patient_defaults, <<-JS
    function( resultObj ) {
      if ( ! Ext.isEmpty(resultObj) ) {
        var invoicePrice = resultObj.price;
                                                    // Set default price according to current Patient ID:
        var cmp = Ext.getCmp( "#{PRICE_FIELD_CMP_ID}" );
        if ( ! (cmp.getValue() > 0) ) {
          cmp.setValue( invoicePrice );
        }
      }
    }  
  JS
  # ---------------------------------------------------------------------------


  # Back-end method called from the +add_recording_take_data_rows+ JS method
  #
  # == Params:
  #  - id : the Patient ID to be retrieved
  #
  # == Returns:
  #  - invokes <tt>afterFindPatientDefaults( hash_result )</tt>, where +hash_result+ is an Hash
  #    having this structure:
  #
  #           { price: default_invoice_price }
  #
  endpoint :find_patient_defaults do |params|
#    logger.debug "\r\n!! ------ in :find_patient_defaults( #{params.inspect} ) -----"
    patient = Patient.where( :id => params[:id].to_i ).first
    result = {}
    if patient
      result[ :price ] = patient.default_invoice_price.to_s
    end
    { :after_find_patient_defaults => result }
  end
  # ---------------------------------------------------------------------------
end
