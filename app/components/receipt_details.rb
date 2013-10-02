#
# Custom Receipt details Form component implementation
#
# - author: Steve A.
# - vers. : 3.05.05.20131002
#
class ReceiptDetails < Netzke::Basepack::FormPanel

  # Component ID used to uniquely address the Patient combo box
  PATIENT_COMBO_FIELD_CMP_ID  = "form_receipt_patient_get_full_name"

  # Component ID used to uniquely address the Receipt Price edit field
  PRICE_FIELD_CMP_ID          = "form_receipt_price"

  # Component ID used to uniquely address the Receipt Text/Description edit field
  DESCRIPTION_FIELD_CMP_ID    = "form_receipt_description"

  # Component ID used to uniquely address the Receipt "is_payed" bool field
  PAYED_FIELD_CMP_ID          = "form_receipt_is_payed"

  # Component ID used to uniquely address the Receipt "is_receipt_delivered" bool field
  DELIVERED_FIELD_CMP_ID      = "form_receipt_is_delivered"


  model 'Receipt'

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
        { :name => :receipt_num,            :field_label => I18n.t(:receipt_num, {:scope=>[:receipt]}),
          # [20130207] Note that this is not correct: an endpoint should be used to retrieve always
          # the updated get_next_receipt_num value. This is just a quick work-around for admin free-form editing mode.
          # Also, note that since *Disabled* fields will not be submitted we can only set the edit field as read-only.
          :default_value => Receipt.get_next_receipt_num(),
          :hidden => read_only_sensible_fields = !( Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :free_edit) ),
          :read_only => read_only_sensible_fields
        },
        { :name => :get_receipt_code,       :field_label => I18n.t(:receipt_num, {:scope=>[:receipt]}),
          :align => 'right', :width => 250,
          :hidden => !read_only_sensible_fields, :read_only => read_only_sensible_fields
        },

        # [20130207] *Disabled* fields will not be submitted. Ext Form.Date field *read_only* attribute
        # does not work (as of the current version).
        # Thus, using the custom flag for read-only status, we toggle "manually" between a pre-fixed
        # display field or an actual date field.
        { :name => :date_receipt,           :field_label => I18n.t(:date_receipt, {:scope=>[:receipt]}),
          :format => 'Y-m-d', :default_value => DateTime.now, :width => 300,
          :hidden => read_only_sensible_fields
        },
        { :name => :display_date_receipt,   :field_label => I18n.t(:date_receipt, {:scope=>[:receipt]}),
          :format => 'Y-m-d', :default_value => DateTime.now, :width => 300,
          :hidden => !read_only_sensible_fields, :xtype => 'displayfield',
          :getter => lambda { |r| r.date_receipt }
        },

        { :name => :patient__get_full_name, :field_label => I18n.t(:patient, {:scope=>[:patient]}),
          :id => PATIENT_COMBO_FIELD_CMP_ID,
          :width => 350, :field_style => 'font-size: 110%; font-weight: bold;',
          # [20121121] For the combo-boxes to have a working query after the 4th char is entered in the edit widget,
          # a lambda statement must be used. Using a pre-computed scope from the Model class prevents Netzke
          # (as of this version) to append the correct WHERE clause to the scope itself (with an inline lambda, instead, it works).
          :scope => lambda { |rel| rel.where(:is_suspended => false).order("surname ASC, name ASC") }
        },
        { :name => :price,                  :field_label => I18n.t(:price, {:scope=>[:receipt]}),
          :id => PRICE_FIELD_CMP_ID, :width => 200, :format => '0.00'
        },
        { :name => :receipt_description,    :field_label => I18n.t(:receipt_description, {:scope=>[:receipt]}),
          :id => DESCRIPTION_FIELD_CMP_ID, :width => 400, :xtype => :textareafield
        },
        { :name => :additional_notes,       :field_label => I18n.t(:additional_notes, {:scope=>[:receipt]}),
          :width => 400, :xtype => :textareafield
        },
        { :name => :is_receipt_delivered,   :field_label => I18n.t(:is_receipt_delivered, {:scope=>[:receipt]}),
          :id => DELIVERED_FIELD_CMP_ID, :width => 120, :field_style => 'min-height: 13px; padding-left: 13px;',
          :unchecked_value => 'false'
        },
        { :name => :is_payed,               :field_label => I18n.t(:is_payed, {:scope=>[:receipt]}),
          :id => PAYED_FIELD_CMP_ID, :width => 120, :field_style => 'min-height: 13px; padding-left: 13px;',
          :unchecked_value => 'false'
        },
        { :name => :notes,                  :field_label => I18n.t(:notes), :width => 400,
          :xtype => :textareafield }
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
          var cmp = Ext.getCmp( "#{PAYED_FIELD_CMP_ID}" );
          var isNotPayed = ! cmp.getValue();
          cmp = Ext.getCmp( "#{DELIVERED_FIELD_CMP_ID}" );
          var isNotDelivered = ! cmp.getValue();
                                                    // Do the update of the form only when the user changes the data and we can proceed:
          if ( (oldValue != newValue) && isNotPayed && isNotDelivered )
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
        var invoiceText  = resultObj.text;
                                                    // Set default price according to current Patient ID:
        var cmp = Ext.getCmp( "#{PRICE_FIELD_CMP_ID}" );
        if ( ! (cmp.getValue() > 0) ) {
          cmp.setValue( invoicePrice );
        }
                                                    // Set default receipt text according to current Patient ID:
        cmp = Ext.getCmp( "#{DESCRIPTION_FIELD_CMP_ID}" );
        if ( cmp.getValue().length == 0 ) {
          cmp.setValue( invoiceText );
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
  #           { price: default_invoice_price, text: default_invoice_text }
  #
  endpoint :find_patient_defaults do |params|
#    logger.debug "\r\n!! ------ in :find_patient_defaults( #{params.inspect} ) -----"
    patient = Patient.where( :id => params[:id].to_i ).first
    result = {}
    if patient
      result[ :price ] = patient.default_invoice_price.to_s
      result[ :text ]  = patient.get_default_receipt_description()
    end
    { :after_find_patient_defaults => result }
  end
  # ---------------------------------------------------------------------------
end
