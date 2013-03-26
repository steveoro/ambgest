#
# Specialized Appointment rows list/grid component implementation
#
# - author: Steve A.
# - vers. : 3.03.02.20130322
#
class AppointmentsGrid < EntityGrid

  action :issue_receipt,  :text => I18n.t(:issue_receipt, :scope =>[:appointment]),
                          :tooltip => I18n.t(:issue_multi_receipt_tooltip, :scope =>[:appointment]),
                          :icon =>"/images/icons/email.png",
                          :disabled => true

  action :void_appointment,
                          :text => I18n.t(:void_appointment, :scope =>[:appointment]),
                          :tooltip => I18n.t(:void_appointment_tooltip, :scope =>[:appointment]),
                          :icon =>"/images/icons/cancel.png",
                          :disabled => true

  action :report_pdf,     :text => I18n.t(:printable_multi_pdf, :scope =>[:appointment]),
                          :tooltip => I18n.t(:printable_multi_pdf_tooltip, :scope =>[:appointment]),
                          :icon =>"/images/icons/page_white_acrobat.png",
                          :disabled => true

  action :report_pdf_copy,:text => I18n.t(:printable_multi_pdf_copy, :scope =>[:appointment]),
                          :tooltip => I18n.t(:printable_multi_pdf_copy_tooltip, :scope =>[:appointment]),
                          :icon =>"/images/icons/page_white_acrobat.png",
                          :disabled => true

  action :use_alt_receipt_title,
                          :xtype   => 'menucheckitem',
                          :text => I18n.t(:alt_receipt_title_description, :scope =>[:receipt]),
                          :disabled => true

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
  js_property :scope_for_i18n, 'appointment'


  js_properties(
    :prevent_header => true,
    :border => false
  )


  add_form_config         :class_name => "AppointmentDetails"
  add_form_window_config  :width => 510, :title => "#{I18n.t(:add_appointment, {:scope=>[:appointment]})}"

  edit_form_config        :class_name => "AppointmentDetails"
  edit_form_window_config :width => 510, :title => "#{I18n.t(:edit_appointment, {:scope=>[:appointment]})}"


  # Override for default bottom bar:
  #
  def default_bbar
    start_items = [
      :report_pdf.action,
      :report_pdf_copy.action,
      "-",                                          # Adds a separator
      :issue_receipt.action,
      :void_appointment.action,
      "-",                                          # Adds a separator
      :show_details.action,
      :manage_patient.action,
      :search.action,
      "-",                                          # Adds a separator
      :add.action, :edit.action
    ]
    possible_items = []                             # (Appointment "raw" delete must have same permission as Receipt delete)
    if ( Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :del) )
      possible_items << :del.action
    end
    end_items = [
      :apply.action,
      "-",
      {
        :menu => [:add_in_form.action, :edit_in_form.action],
        :text => I18n.t(:edit_in_form),
        :icon => "/images/icons/application_form.png"
      },
      "-",
      :row_counter.action
    ]
    start_items + possible_items + end_items
  end


  # Override for default context menu
  #
  def default_context_menu
    start_items = [
      :row_counter.action,
      "-",
      :report_pdf.action,
      :report_pdf_copy.action,
      :use_alt_receipt_title.action,
      "-",                                          # Adds a separator
      :issue_receipt.action,
      :void_appointment.action,
      "-",                                          # Adds a separator
      :show_details.action,
      :manage_patient.action,
      "-",                                          # Adds a separator
      :add.action, :edit.action
    ]
    possible_items = []
    if ( Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :del) )
      possible_items << :del.action
    end
    end_items = [
      :apply.action,
      "-",
      {
        :menu => [:add_in_form.action, :edit_in_form.action],
        :text => I18n.t(:edit_in_form),
        :icon => "/images/icons/application_form.png"
      }
    ]
    start_items + possible_items + end_items
  end

  # ---------------------------------------------------------------------------


  def configuration
    # ASSERT: assuming current_user is always set for this grid component:
    super.merge(
      :persistence => true,
      # [Steve, 20120131]
      # FIXME The Netzke endpoint, once configured, ignores any subsequent request to turn off or resize the pagination
      # TODO Either wait for a new Netzke release that changes this behaviour, or rewrite from scratch the endpoint implementation for the service of grid data retrieval
#      :enable_pagination => false,
      # [Steve, 20120914] It seems that the LIMIT parameter used during column sort can't be toggled off, so we put an arbitrary 10Tera row count limit per page to get all the rows: 
#      :rows_per_page => 1000000000000,
      :min_width => 750,
      :strong_default_attrs => { :is_payed => false }.merge( super[:strong_default_attrs] || {} ),
      :columns => [
#          { :name => :created_on, :label => I18n.t(:created_on), :width => 80,   :read_only => true,
#            :format => 'Y-m-d' },
#          { :name => :updated_on, :label => I18n.t(:updated_on), :width => 120,  :read_only => true,
#            :format => 'Y-m-d' },

          { :name => :date_schedule,          :label => I18n.t(:date_schedule, {:scope=>[:appointment]}), :width => 110,
            :format => 'Y-m-d, H:i', :default_value => DateTime.now, :summary_type => :count
          },

          { :name => :patient__get_full_name, :label => I18n.t(:patient, {:scope=>[:patient]}), :width => 150,
            :width => 180,
            # [20121121] For the combo-boxes to have a working query after the 4th char is entered in the edit widget,
            # a lambda statement must be used. Using a pre-computed scope from the Model class prevents Netzke
            # (as of this version) to append the correct WHERE clause to the scope itself (with an inline lambda, instead, it works).
            :scope => lambda { |rel| rel.where(:is_suspended => false).order("surname ASC, name ASC") },
            :sorting_scope => :sort_appointment_by_patient
          },

          { :name => :price,                  :label => I18n.t(:price, {:scope=>[:appointment]}), :width => 60,
            :xtype => 'numbercolumn', :align => 'right', :format => '0.00', :summary_type => :sum
          },
          { :name => :additional_notes,       :label => I18n.t(:additional_notes, {:scope=>[:appointment]}),
            :width => 250 },

          { :name => :is_receipt_issued,      :label => I18n.t(:is_receipt_issued, {:scope=>[:appointment]}),
            :renderer => 'renderTickedFlag',  :width => 70, :sorting_scope => :sort_appointment_by_receipt_num
          },
          # Used for quick-access to association rows by JS selection:
          { :name => :get_safe_receipt_id,    :label => I18n.t(:receipt_id, {:scope=>[:receipt]}),
            :hidden => true, :read_only => true, :disabled => true
          },
          { :name => :receipt_code,           :label => I18n.t(:receipt_num, {:scope=>[:receipt]}),
            :width => 80, :align => 'right',  :sorting_scope => :sort_appointment_by_receipt_num
          },
          { :name => :is_receipt_delivered,   :label => I18n.t(:is_receipt_delivered, {:scope=>[:receipt]}),
            :renderer => 'renderTickedFlag',  :width => 80, :sorting_scope => :sort_appointment_by_is_receipt_delivered
          },
          { :name => :is_payed,               :label => I18n.t(:is_payed, {:scope=>[:appointment]}),
            :unchecked_value => 'false'
          },
          { :name => :notes,                  :label => I18n.t(:notes), :flex => 1 }
      ]
    )
  end

  # ---------------------------------------------------------------------------


  js_method :init_component, <<-JS
    function() {
      #{js_full_class_name}.superclass.initComponent.call(this);
                                                    // Clear internal PDF options flag:
      this.actions.useAltReceiptTitle.checked = false;
                                                    // Stack another listener on top over the one defined in EntityGrid:
      this.getSelectionModel().on('selectionchange',
        function(selModel) {
          this.actions.managePatient.setDisabled( selModel.getCount() < 1 );

          var canFreeEdit = ( "#{ Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :free_edit) }" != 'false' );
          var selItems = selModel.selected.items;
          var canEditPatient = true;
          var iReceiptsFound = 0;

          for ( i = 0; i < selItems.length; i++ ) {
            if ( selItems[i].data != null ) {       // To disable Patient editing all selected rows must pass this condition:
              canEditPatient = canEditPatient &&
                               ( selItems[i].get('is_receipt_delivered') != 'true' ) &&
                               ( selItems[i].get('is_receipt_issued') != 'true' ) &&
                               ( ! selItems[i].get('is_payed') );
              // [20130211] Note that "!= 'true'" takes into account both undefined and false values for getter fields returning string booleans
              if ( selItems[i].data.receipt_code != null && selItems[i].data.receipt_code.length > 0 )
                iReceiptsFound++;                   // Increase receipt count when found in selected rows
            }
          }
          canEditPatient = ( canFreeEdit || canEditPatient );
                                                    // Disable PDF creation when there is nothing selected to print:
          var isPDFDisabled = ( iReceiptsFound == 0 );
          this.actions.reportPdf.setDisabled( isPDFDisabled );
          this.actions.reportPdfCopy.setDisabled( isPDFDisabled );
          this.actions.useAltReceiptTitle.setDisabled( isPDFDisabled );
                                                    // Disable Issue Receipt if there are no uninvoiced rows selected:
          this.actions.issueReceipt.setDisabled( iReceiptsFound >= selItems.length );
                                                    // Disable Void Appointment if there is already a Receipt or it has been already payed
          this.actions.voidAppointment.setDisabled( ( selModel.getCount() > 0)  && !canEditPatient );

                                                    // Toggle on-off actions according to selected context:
          this.actions.edit.setDisabled( !canEditPatient );
          this.actions.editInForm.setDisabled( !canEditPatient );
        },
        this
      );
                                                    // Skip edit events if the receipt has been already given away:
      this.getPlugin('celleditor').on( 'beforeedit',
        function( editEvent, eOpts ) {
          var canFreeEdit = ( "#{ Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :free_edit) }" != 'false' );
          // [20130211] Note that "!= 'true'" takes into account both undefined and false values for getter fields returning string booleans
          var canEditPatient = ( editEvent.record != null ) &&
                               ( editEvent.record.get('is_receipt_delivered') != 'true' ) &&
                               ( editEvent.record.get('is_receipt_issued') != 'true' ) &&
                               ( ! editEvent.record.get('is_payed') );
// DEBUG
//          console.log( "canFreeEdit=" + canFreeEdit );
//          console.log( "canEditPatient=" + canEditPatient );
          canEditPatient = ( canFreeEdit || canEditPatient );
          editEvent.cancel = ( ! canEditPatient );
        },
        this
      );
                                                    // --- Update cells on Patient combo edit:
      this.getPlugin('celleditor').on( 'validateedit',
        function( editor, editEvent, eOpts ) {      // Do the update of the grid only when the user changes the correct field AND we can proceed:
          // [20130211] Note that "!= 'true'" takes into account both undefined and false values for getter fields returning string booleans
          if ( (editEvent.record != null) &&
               (editEvent.record.get('is_receipt_delivered') != 'true') &&
               (editEvent.record.get('is_receipt_issued') != 'true') && 
               (! editEvent.record.get('is_payed')) && 
               (editEvent.field == 'patient__get_full_name') )
                                                    // Invoking this endpoint will overwrite the price and description fields:
            this.findPatientDefaultsForGrid({ 'id': editEvent.value, 'idx': editEvent.rowIdx });
        },
        this
      );
                                                    // As soon as the grid is ready, sort it by default:
      this.on( 'viewready',
        function( gridPanel, eOpts ) {
          gridPanel.store.sort([ { property: 'date_schedule', direction: 'DESC' } ]);
        },
        this
      );
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------


  js_method :after_find_patient_defaults_for_grid, <<-JS
    function( resultObj ) {
      if ( ! Ext.isEmpty(resultObj) ) {
        var invoicePrice = resultObj.price;
        var rowIndex     = resultObj.idx;
                                                    // Retrieve the grid DataStore and use it for the update:
        var store = this.getStore();
        var row = store.getAt( rowIndex );
                                                    // Set default values according to current Patient ID:
        if ( row.get('price') < 0.01 ) {
          row.set( 'price', invoicePrice );
        }
      }
    }  
  JS


  # Back-end method called from the +add_recording_take_data_rows+ JS method
  #
  # == Params:
  #  - id  : the Patient ID to be retrieved
  #  - idx : the Receipt record row index being edited on the grid (returned as reference)
  #
  # == Returns:
  #  - invokes <tt>afterFindPatientDefaultsForGrid( hash_result )</tt>, where +hash_result+ is an Hash
  #    having this structure:
  #
  #           { price: default_invoice_price, idx: edited record row index on the grid view }
  #
  endpoint :find_patient_defaults_for_grid do |params|
#    logger.debug "\r\n!! ------ in :find_patient_defaults_for_grid( #{params.inspect} ) -----"
    patient = Patient.where( :id => params[:id].to_i ).first
    result = {}
    if patient
      result[ :price ]  = patient.default_invoice_price.to_s
      result[ :idx ]    = params[ :idx ]
    end
    { :after_find_patient_defaults_for_grid => result }
  end
  # ---------------------------------------------------------------------------


  # Custom renderer for the Grid component
  #
  js_method :render_ticked_flag, <<-JS
    function( value ){
      if ( value == null || value == 'false' || value == 'False' || value == 'FALSE' || value == '' || value == '0' ) {
        return '';
      }
      return "<img height='14' border='0' align='top' src='/images/icons/tick.png' />";
    }
  JS

  # Custom renderer for the Form component
  #
  js_method :render_convert_string_to_bool, <<-JS
    function( value ){
      if ( value == null || value == 'false' || value == 'False' || value == 'FALSE' || value == '' || value == '0' ) {
        return false;
      }
      return true;
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------


  # Scans selection model and collects all the rows that DO NOT HAVE a Receipt,
  # and ask confirmation before proceeding.
  #
  # Since the method calling is asynchronous and this method is used in 2 actions,
  # the parameter is just a flag to discriminate between the 2 callers.
  #
  js_method :collect_processable_rows_without_receipt, <<-JS
    function( isCallingFromVoidAppointment ) {
      var selModel = this.getSelectionModel();
      var processableRows = new Array();

      if ( selModel.hasSelection() ) {
        var selItems = selModel.selected.items;
        var iSkippedRows = 0;
        for ( i = 0; i < selItems.length; i++ ) {
          if ( selItems[i].data != null ) {
            if ( selItems[i].data.receipt_code != null && selItems[i].data.receipt_code.length > 0 ) {
              iSkippedRows++;
            }
          else {                                    // No receipt issued for current row? That is good:
              processableRows.push( selItems[i].data.id )
            }
          }
        }

        if ( iSkippedRows > 0 ) {                   // Signal skipped rows to the user:
          this.netzkeFeedback( "#{I18n.t(:some_rows_were_skipped_because_invoiced)}" );
        }
                                                    // Found any processable rows?
        if ( processableRows.length > 0 ) {         // Ask issue-receipt confirmation:
          Ext.MessageBox.confirm( "#{I18n.t(:confirmation, {:scope=>[:netzke,:basepack,:grid_panel]})}", "#{I18n.t(:are_you_sure, {:scope=>[:netzke,:basepack,:grid_panel]})}",
            function( responseText ) {
              if ( responseText == 'yes' ) {        // -- VOID APPOINTMENTS:
                if ( isCallingFromVoidAppointment ) {
                  this.voidAppointmentsOnGrid({ 'data': processableRows });
                }
                else {                              // -- ISSUE NEW RECEIPTS:
                  this.invokePostOnHiddenForm( 'frmPostIssueReceipt', 'data', processableRows );
                }
              }
            },
            this
          );
        }
        else
          this.netzkeFeedback( "#{I18n.t(:warning_no_data_to_send)}" );
      }
      else
        this.netzkeFeedback( "#{I18n.t(:warning_no_data_to_send)}" );
    }
  JS
  # ---------------------------------------------------------------------------


  # Cancel (Void) an Appointment:
  # (Uses the same conditions as "Issue Receipt")
  #
  js_method :on_void_appointment, <<-JS
    function() {
      this.collectProcessableRowsWithoutReceipt( true /*calling from 'void appointments'*/ );
    }
  JS


  js_method :after_void_appointments_on_grid, <<-JS
    function( resultObj ) {
      if ( ! Ext.isEmpty(resultObj) ) {
        this.netzkeFeedback( resultObj + " #{I18n.t(:appointments_cancelled, {:scope=>[:appointment]})}" );
        this.getStore().load();                     // Refresh the grid
      }
    }  
  JS


  # Back-end method called from the +:void_appointment+ action handler
  #
  # == Params:
  #  - data : the Appointment ID list to be cancelled
  #
  # == Returns:
  #  - the number of rows processed
  #
  endpoint :void_appointments_on_grid do |params|
    logger.debug "\r\n!! ------ in :void_appointments_on_grid( #{params.inspect} ) -----"
                                                    # Parse params:
    id_list = params[:data]
    logger.debug "\r\nid_list: #{id_list.inspect}"

    if ( id_list.size > 0 )                         # 'destroy' is less efficient than 'delete', but honors all validation callbacks
      logger.debug "\r\nBEFORE Appointment.destroy..."
      id_list.reject!{ |e| e < 1 }                  # 0 ids come from rows not saved/applied yet
      Appointment.destroy( id_list )
      logger.debug "\r\nDone."
    end
    logger.debug "\r\nReturning..."
    { :after_void_appointments_on_grid => id_list.size }
  end
  # ---------------------------------------------------------------------------


  # Issues a new Receipt based on selection.
  # (Uses the same conditions as "Void Appointments")
  #
  js_method :on_issue_receipt, <<-JS
    function() {
      this.collectProcessableRowsWithoutReceipt( false /*calling from 'issue receipt'*/ );
    }
  JS


  # Invokes a controller path sending in all the (encoded) IDs selected inside rowDataArray.
  #
  js_method :invoke_post_on_hidden_form, <<-JS
    function( formId, dataFieldId, rowDataArray ) {
      if ( rowDataArray.length > 0 ) {              // If there is data, process it:
        this.setDisabled( true );
        var encodedData = Ext.JSON.encode( rowDataArray );
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


  # Handler for the checkbox item inside toolbar and context menu.
  # Synchronizes the checkboxes state with the value of the internal flag variable.
  #
  js_method :on_use_alt_receipt_title, <<-JS
    function( item ) {
      this.actions.useAltReceiptTitle.checked = item.checked;
    }
  JS
  # ---------------------------------------------------------------------------


  # Front-end JS event handler for the action 'report_pdf'
  #
  js_method :on_report_pdf, <<-JS
    function() {
      this.collectProcessableData( "#{ Netzke::Core.controller.report_detail_receipts_path( :type=>'pdf' ) }" );
    }
  JS


  # Front-end JS event handler for the action 'report_pdf_copy'
  #
  js_method :on_report_pdf_copy, <<-JS
    function() {
      this.collectProcessableData( "#{ Netzke::Core.controller.report_detail_receipts_path( :type=>'pdf', :is_internal_copy=>'1' ) }" );
    }
  JS


  # Scans selection model and collects all the rows that HAVE a Receipt
  #
  js_method :collect_processable_data, <<-JS
    function( controllerPath ) {
      var selModel = this.getSelectionModel();
      var processableRows = new Array();

      if ( selModel.hasSelection() ) {
        var selItems = selModel.selected.items;
        var iSkippedRows = 0;
        for ( i = 0; i < selItems.length; i++ ) {
          if ( selItems[i].data != null ) {
            if ( selItems[i].data.get_safe_receipt_id > 0 ) {
              processableRows.push( selItems[i].data.get_safe_receipt_id );
            }
          else {                                    // No receipt issued for current row? Skip PDF generation:
              iSkippedRows++;
            }
          }
        }

        if ( iSkippedRows > 0 ) {                   // Signal skipped rows to the user:
          this.netzkeFeedback( "#{I18n.t(:some_rows_were_skipped_because_not_invoiced)}" );
        }
                                                    // Found any processable rows?
        if ( processableRows.length > 0 ) {
          this.invokeFilteredCtrlMethod( controllerPath, processableRows );
        }
        else
          this.netzkeFeedback( "#{I18n.t(:warning_no_data_to_send)}" );
      }
      else
        this.netzkeFeedback( "#{I18n.t(:warning_no_data_to_send)}" );
    }
  JS


  # Invokes a controller path sending in all the (encoded) IDs selected inside rowDataArray.
  #
  js_method :invoke_filtered_ctrl_method, <<-JS
    function( controllerPath, rowDataArray ) {
      if ( rowDataArray.length > 0 ) {              // If there is data, send a request:
        var encodedData = Ext.JSON.encode( rowDataArray );

        if ( this.actions.useAltReceiptTitle.checked ) {
          controllerPath = controllerPath + "&use_alt_receipt_title=1";
          // [20130208] Reset the flag after usage, thus, next time the menu will be rendered,
          // it will have a correct starting 'false' value (there is no getter for the internal flag
          // and the menu item starts from scratch each time it is rendered)
          this.actions.useAltReceiptTitle.checked = false;
        }
                                                    // Redirect to this URL: (which performs a send_data rails command)                                                          
        location.href = controllerPath + "&data=" + encodedData;
      }
      else {
        this.netzkeFeedback( "#{I18n.t(:warning_no_data_to_send)}" );
      }
    }
  JS
  # ---------------------------------------------------------------------------


  # Invokes "manage/:id/patient" according to the patient_id of the currently selected
  # Receipt row.
  #
  js_method :on_manage_patient, <<-JS
    function() {
      var fld = this.getSelectionModel().selected.first().data;
      var managePath = this.targetForPatientManage.replace( '-1', fld[ 'patient__get_full_name' ] );
      this.setDisabled( true );
      location.href = managePath;
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------

end
