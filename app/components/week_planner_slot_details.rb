#
# Week-planner custom form "editor" component
#
# - author: Steve A.
# - vers. : 0.34.20130215
#
class WeekPlannerSlotDetails < Netzke::Basepack::FormPanel

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
  # ---------------------------------------------------------------------------


  action :issue_receipt,  :text => I18n.t(:issue_receipt, :scope =>[:appointment]),
                          :tooltip => I18n.t(:issue_receipt_tooltip, :scope =>[:appointment]),
                          :icon =>"/images/icons/email.png",
                          :disabled => true

  action :report_pdf,     :text => I18n.t(:printable_pdf, :scope =>[:appointment]),
                          :tooltip => I18n.t(:printable_pdf_tooltip, :scope =>[:appointment]),
                          :icon =>"/images/icons/page_white_acrobat.png",
                          :disabled => true

  action :report_pdf_copy,:text => I18n.t(:printable_pdf_copy, :scope =>[:appointment]),
                          :tooltip => I18n.t(:printable_pdf_copy_tooltip, :scope =>[:appointment]),
                          :icon =>"/images/icons/page_white_acrobat.png",
                          :disabled => true
  # ---------------------------------------------------------------------------

  action :manage_patient,
                          :text => I18n.t(:patient, :scope =>[:patient]),
                          :tooltip => I18n.t(:manage_patient_tooltip, :scope =>[:patient]),
                          :icon =>"/images/icons/user_go.png",
                          :disabled => true
  # ---------------------------------------------------------------------------

  # Defines a dummy target for the "patient manage" action
  #
  js_property :target_for_patient_manage, Netzke::Core.controller.manage_patient_path( :locale => I18n.locale, :id => -1 )
  # ---------------------------------------------------------------------------


  model 'Appointment'


  js_properties(
    :prevent_header => true,
    :header => false,
    :border => false
  )


  def configuration
   super.merge(
      :persistence => true,
      :min_width => 500
   )
  end


  # Top bar with custom actions
  #
  js_property :tbar, [
     :report_pdf.action, :report_pdf_copy.action,
     "-",                                           # Adds a separator
     :issue_receipt.action, "-", :manage_patient.action
  ]


  items [                                           # ( == What follows is a minor customization of the config from AppointmentsGrid::default_fields_for_forms == )
      {
        :column_width => 1.00, :border => false,
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
            :id => PAYED_FIELD_CMP_ID, :width => 120, :unchecked_value => 'false'
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


  # Custom renderer for the Form component
  #
  js_method :render_convert_string_to_bool, <<-JS
    function( value ){
      if ( value == 'false' || value == 'False' || value == 'FALSE' || value == '' || value == '0' ) {
        return false;
      }
      return true;
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------


  # Front-end JS event handler for the action 'report_pdf'
  #
  js_method :on_report_pdf, <<-JS
    function() {
      this.invokeCtrlMethodWithCachedId( "#{ Netzke::Core.controller.report_detail_receipts_path( :type=>'pdf' ) }" );
    }
  JS


  # Front-end JS event handler for the action 'report_pdf_copy'
  #
  js_method :on_report_pdf_copy, <<-JS
    function() {
      this.invokeCtrlMethodWithCachedId( "#{ Netzke::Core.controller.report_detail_receipts_path( :type=>'pdf', :is_internal_copy=>'1' ) }" );
    }
  JS


  # Invokes a controller path sending in the previously cached Receipt ID
  #
  js_method :invoke_ctrl_method_with_cached_id, <<-JS
    function( controllerPath ) {
      var iId = this.actions.reportPdf.receiptId;
                                                    // If there is an already created Receipt associated, process it:
      if ( iId > 0 ) {
        var encodedData = "[" + iId +"]";                                                          
                                                    // Redirect to this URL: (which performs a send_data rails command)
        location.href = controllerPath + "&data=" + encodedData;
      }
      else {
        this.netzkeFeedback( "#{I18n.t(:warning_no_data_to_send)}" );
      }
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------


  # Ask confirmation before proceeding:
  #
  js_method :on_issue_receipt, <<-JS
    function() {
      Ext.MessageBox.confirm( "#{I18n.t(:confirmation, {:scope=>[:netzke,:basepack,:grid_panel]})}", "#{I18n.t(:are_you_sure, {:scope=>[:netzke,:basepack,:grid_panel]})}",
        function( responseText ) {
          if ( responseText == 'yes' ) {
            this.invokePostOnHiddenForm( 'frmPostIssueReceipt', 'data' );
          }
        },
        this
      );
    }
  JS


  # Invokes a controller path sending in all the (encoded) IDs currently available on
  # the data store.
  #
  js_method :invoke_post_on_hidden_form, <<-JS
    function( formId, dataFieldId ) {
      var frmFields = this.getForm().getFields();
      var iId = frmFields.getAt(0).getValue();      // The Id field is at index 0
                                                    // If there is data, process it:
      if ( iId > 0 ) {
        this.setDisabled( true );
        var encodedData = "[" + iId +"]";
        var form = Ext.get( formId );
        var hiddenField = Ext.get( dataFieldId );
        hiddenField.dom.value = encodedData;
        form.dom.submit();
      }
      else {
        this.netzkeFeedback( "#{I18n.t(:warning_no_data_to_send)}" );
      }
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------


  # Invokes "manage/:id/patient" according to the patient_id of the currently selected
  # Receipt row.
  #
  js_method :on_manage_patient, <<-JS
    function() {
      var patientId = this.getForm().findField( 'patient__get_full_name' ).getValue()
      var managePath = this.targetForPatientManage.replace( '-1', patientId );
      this.setDisabled( true );
      location.href = managePath;
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
end
