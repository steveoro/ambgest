#
# Specialized Receipt rows list/grid component implementation
#
# - author: Steve A.
# - vers. : 3.03.02.20130322
#
class ReceiptsGrid < EntityGrid

  action :report_pdf,
                        :text => I18n.t(:printable_multi_pdf, :scope =>[:appointment]),
                        :tooltip => I18n.t(:printable_multi_pdf_tooltip, :scope =>[:appointment]),
                        :icon =>"/images/icons/page_white_acrobat.png"

  action :report_pdf_copy,
                        :text => I18n.t(:printable_multi_pdf_copy, :scope =>[:appointment]),
                        :tooltip => I18n.t(:printable_multi_pdf_copy_tooltip, :scope =>[:appointment]),
                        :icon =>"/images/icons/page_white_acrobat.png"

  action :use_alt_receipt_title,
                        :xtype   => 'menucheckitem',
                        :text => I18n.t(:alt_receipt_title_description, :scope =>[:receipt])

  action :manage_patient,
                        :text => I18n.t(:patient, :scope =>[:patient]),
                        :tooltip => I18n.t(:manage_patient_tooltip, :scope =>[:patient]),
                        :icon =>"/images/icons/user_go.png",
                        :disabled => true
  # ---------------------------------------------------------------------------

  action :export_txt,   :text => I18n.t(:export_txt, :scope =>[:appointment]),
                        :tooltip => I18n.t(:export_txt_tooltip, :scope =>[:appointment]),
                        :icon =>"/images/icons/page_white_text.png"

  action :export_csv,
                        :text => I18n.t(:export_csv_full, :scope =>[:appointment]),
                        :tooltip => I18n.t(:export_csv_full_tooltip, :scope =>[:appointment]),
                        :icon =>"/images/icons/page_white_excel.png"
  # ---------------------------------------------------------------------------

  # Defines a dummy target for the "patient manage" action
  #
  js_property :target_for_patient_manage, Netzke::Core.controller.manage_patient_path( :locale => I18n.locale, :id => -1 )
  # ---------------------------------------------------------------------------


  model 'Receipt'
  js_property :scope_for_i18n, 'receipt'

  js_properties(
    :prevent_header => true,
    :border => false
  )


  add_form_config         :class_name => "ReceiptDetails"
  add_form_window_config  :width => 510, :title => "#{I18n.t(:add_receipt, {:scope=>[:receipt]})}"

  edit_form_config        :class_name => "ReceiptDetails"
  edit_form_window_config :width => 510, :title => "#{I18n.t(:edit_receipt, {:scope=>[:receipt]})}"


  # Override for default bottom bar:
  #
  def default_bbar
    start_items = [
      :report_pdf.action,
      :report_pdf_copy.action,
      {
        :menu => [:export_txt.action, :export_csv.action],
        :text => I18n.t(:data_export),
        :icon => "/images/icons/folder_table.png"
      },
      "-",
      :show_details.action,
      :manage_patient.action,
      :search.action,
      "-"
    ]
    possible_items = []
    if ( Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :free_add) )
      possible_items << :add.action
    end
    if ( Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :del) )
      possible_items << :del.action
    end
    end_items = [
      :edit.action, :apply.action,
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
      :report_pdf.action,
      :report_pdf_copy.action,
      :use_alt_receipt_title.action,
      "-",                                          # Adds a separator
      {
        :menu => [:export_txt.action, :export_csv.action],
        :text => I18n.t(:data_export),
        :icon => "/images/icons/folder_table.png"
      },
      "-",                                          # Adds a separator
      :show_details.action,
      :manage_patient.action,
      "-"
    ]
    possible_items = []
    if ( Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :free_add) )
      possible_items << :add.action
    end
    if ( Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :del) )
      possible_items << :del.action
    end
    end_items = [
      :edit.action, :apply.action,
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

  # ---------------------------------------------------------------------------


  def configuration
    # ASSERT: assuming current_user is always set for this grid component:
    super.merge(
      :persistence => true,
      # [Steve, 20120131]
      # FIXME The Netzke endpoint, once configured, ignores any subsequent request to turn off or resize the pagination
      # TODO Either wait for a new Netzke release that changes this behavior, or rewrite from scratch the endpoint implementation for the service of grid data retrieval
#      :enable_pagination => false,
      # [Steve, 20120914] It seems that the LIMIT parameter used during column sort can't be toggled off, so we put an arbitrary 10Tera row count limit per page to get all the rows: 
#      :rows_per_page => 1000000000000,
      :min_width => 750,
      :strong_default_attrs => super[:strong_default_attrs],
      :columns => [
#          { :name => :created_on, :label => I18n.t(:created_on), :width => 80,   :read_only => true,
#            :format => 'Y-m-d' },
#          { :name => :updated_on, :label => I18n.t(:updated_on), :width => 120,  :read_only => true,
#            :format => 'Y-m-d' },

          # Used for quick-access to association rows by JS selection:
          { :name => :receipt_num,            :label => I18n.t(:receipt_num, {:scope=>[:receipt]}),
            # [20130207] Note that this is not correct: an endpoint should be used to retrieve always
            # the updated get_next_receipt_num value. This is just a quick work-around for admin free-form editing mode.
            # Also, note that since *Disabled* fields will not be submitted we can only set the edit field as read-only.
            :default_value => Receipt.get_next_receipt_num(),
            :hidden => ( read_only_sensible_fields = !( Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :free_edit) ) ),
            :read_only => read_only_sensible_fields, :summary_type => :count
          },
          { :name => :get_receipt_code,       :label => I18n.t(:receipt_num, {:scope=>[:receipt]}),
            :width => 80, :align => 'right',  :sorting_scope => :sort_receipt_by_receipt_code,
            :hidden => !read_only_sensible_fields,
            :read_only => read_only_sensible_fields, :summary_type => :count
          },

          { :name => :date_receipt,           :label => I18n.t(:date_receipt, {:scope=>[:receipt]}), :width => 80,
            :format => 'Y-m-d', :default_value => DateTime.now,
            :read_only => read_only_sensible_fields
          },

          { :name => :patient__get_full_name, :label => I18n.t(:patient, {:scope=>[:patient]}), :width => 150,
            :width => 180,
            # [20121121] For the combo-boxes to have a working query after the 4th char is entered in the edit widget,
            # a lambda statement must be used. Using a pre-computed scope from the Model class prevents Netzke
            # (as of this version) to append the correct WHERE clause to the scope itself (with an inline lambda, instead, it works).
            :scope => lambda { |rel| rel.where(:is_suspended => false).order("surname ASC, name ASC") },
            :sorting_scope => :sort_receipt_by_patient
          },

          { :name => :price,                  :label => I18n.t(:price, {:scope=>[:receipt]}), :width => 60,
            :xtype => 'numbercolumn', :align => 'right', :format => '0.00', :summary_type => :sum
          },
          { :name => :receipt_description,    :label => I18n.t(:receipt_description, {:scope=>[:receipt]}),
            :width => 250
          },
          { :name => :additional_notes,       :label => I18n.t(:additional_notes, {:scope=>[:receipt]}),
            :width => 250 },

          { :name => :is_receipt_delivered,   :label => I18n.t(:is_receipt_delivered, {:scope=>[:receipt]}),
            :width => 80, :unchecked_value => 'false'
          },
          { :name => :is_payed,               :label => I18n.t(:is_payed, {:scope=>[:receipt]}),
            :width => 60, :unchecked_value => 'false'
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
          var canEditRow = ( selModel.getCount() > 0 );
                                                    // Toggle on-off actions according to selected context:
          this.actions.add.setDisabled( !canFreeEdit );
          this.actions.edit.setDisabled( !canEditRow );
          this.actions.editInForm.setDisabled( !canEditRow );
          // [20130211] Note: add_in_form action must be always available, while the add on grid not
          // (it cannot work for normal users, since it has read_only_sensible_fields set on date_receipt needed for the data-post)
        },
        this
      );

/* [Steve, 20130514] For the moment, we won't do the following check since is too restrictive
                     and it doesn't work as expected by the user. The code is kept here just
                     as reference for future questions.
                                                    // Skip edit events if the invoice has been already given to the patient:
      this.getPlugin('celleditor').on( 'beforeedit',
        function( editEvent, eOpts ) {
          var canFreeEdit = ( "#{ Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :free_edit) }" != 'false' );
          var canEditPatient = ( editEvent.record != null ) &&
                               ( ! editEvent.record.get('is_receipt_delivered') ) &&
                               ( ! editEvent.record.get('is_payed') );
// DEBUG
//          console.log( "canFreeEdit=" + canFreeEdit );
//          console.log( "canEditPatient=" + canEditPatient );
          canEditPatient = ( canFreeEdit || canEditPatient );
          editEvent.cancel = ( ! canEditPatient );
        },
        this
      );
*/
                                                    // --- Update cells on Patient combo edit:
      this.getPlugin('celleditor').on( 'validateedit',
        function( editor, editEvent, eOpts ) {      // Do the update of the grid only when the user changes the correct field AND we can proceed:
          if ( ( editEvent.record != null ) &&
               (! editEvent.record.get('is_receipt_delivered')) &&
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
          gridPanel.store.sort([ { property: 'date_receipt', direction: 'DESC' } ]);
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
        var invoiceText  = resultObj.text;
        var rowIndex     = resultObj.idx;
                                                    // Retrieve the grid DataStore and use it for the update:
        var store = this.getStore();
        var row = store.getAt( rowIndex );
                                                    // Set default values according to current Patient ID:
        if ( row.get('price') < 0.01 ) {
          row.set( 'price', invoicePrice );
        }
        if ( row.get('receipt_description').length == 0 ) {
          row.set( 'receipt_description', invoiceText );
        }
      }
    }  
  JS
  # ---------------------------------------------------------------------------


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
  #           { price: default_invoice_price, text: default_invoice_text, idx: edited record row index on the grid view }
  #
  endpoint :find_patient_defaults_for_grid do |params|
#    logger.debug "\r\n!! ------ in :find_patient_defaults_for_grid( #{params.inspect} ) -----"
    patient = Patient.where( :id => params[:id].to_i ).first
    result = {}
    if patient
      result[ :price ]  = patient.default_invoice_price.to_s
      result[ :text ]   = patient.get_default_receipt_description()
      result[ :idx ]    = params[ :idx ]
    end
    { :after_find_patient_defaults_for_grid => result }
  end
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


  # Front-end JS event handler for the action 'export_txt'
  #
  js_method :on_export_txt, <<-JS
    function() {
      this.collectProcessableData( "#{ Netzke::Core.controller.report_detail_receipts_path( :type=>'txt' ) }" );
    }
  JS


  # Front-end JS event handler for the action 'export_csv'
  #
  js_method :on_export_csv, <<-JS
    function() {
      this.collectProcessableData( "#{ Netzke::Core.controller.report_detail_receipts_path( :type=>'csv' ) }" );
    }
  JS


  # Scans selection model and collects all the rows that are actually 'processable'
  #
  js_method :collect_processable_data, <<-JS
    function( controllerPath ) {
      var selModel = this.getSelectionModel();
      var processableRows = new Array();

      if ( selModel.hasSelection() ) {
        var selItems = selModel.selected.items;
        var iSkippedRows = 0;
        for ( i = 0; i < selItems.length; i++ ) {
          if ( selItems[i].data != null )
            processableRows.push( selItems[i].data.id );
          else
            iSkippedRows++;
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
