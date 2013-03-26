#
# == Custom Week-planner component implementation
#
# - author:   Steve A.
# - version:  3.03.03.20130326
#
# A custom panel that acts as a full-fledged week planner.
#
class WeekPlannerPanel < Netzke::Basepack::BorderLayoutPanel 

  js_properties(
    :prevent_header => true,
    :header => false,
    :border => true
  )

  js_property :win_planner_slot_frm


  def configuration
    super.merge(
      :persistence => true,
      :items => [
        :filtering_header.component( :region => :north ),
        :planner_grid.component( :region => :center )
      ]
    )
  end
  # ---------------------------------------------------------------------------


  # Internal components used only as pop-up forms for editing/creating planner slot contents
  #
  component :add_form do
    form_config = {
      :class_name => "WeekPlannerSlotDetails",
      :record => Appointment.new()
    }

    {
      :lazy_loading => true,
      :class_name => "Netzke::Basepack::GridPanel::RecordFormWindow",
      :title => "#{I18n.t(:add_appointment, {:scope=>[:appointment]})}",
      :min_width => 450,
      :button_align => "right",
      :items => [ form_config ]
    }
  end


  component :edit_form do
    form_config = {
      :class_name => "WeekPlannerSlotDetails",
      # :record_id gets assigned by deliver_component dynamically, at the moment of loading
    }

    {
      :lazy_loading => true,
      :class_name => "Netzke::Basepack::GridPanel::RecordFormWindow",
      :title => "#{I18n.t(:edit_appointment, {:scope=>[:appointment]})}",
      :min_width => 450,
      :button_align => "right",
      :items => [ form_config ]
    }
  end
  # ---------------------------------------------------------------------------


  component :filtering_header do
    {
      :class_name => "PlannerCommandPanel",
      :filtering_date => component_session[PlannerCommandPanel::FILTERING_DATE_CMP_SYM] ||= Date.today.strftime(AGEX_FILTER_DATE_FORMAT_SQL)
    }
  end


  component :planner_grid do
    {
      :class_name     => "PlannerGrid",
      :filtering_date => ( component_session[PlannerCommandPanel::FILTERING_DATE_CMP_SYM] ||= Date.today.strftime(AGEX_FILTER_DATE_FORMAT_SQL) ),
      :schedules      => ( component_session[:schedules] ||= config[:schedules] ),
      :appointments   => ( component_session[:appointments] ||= config[:appointments] )
    }
  end
  # ---------------------------------------------------------------------------


  js_method :init_component, <<-JS
    function() {
      #{js_full_class_name}.superclass.initComponent.call( this );

      this.updateFilteringScope('');                // This will either use Date.today or the one stored into the component session
    }  
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------


  # Main slot cell button handler, called from PlannerGrid.
  # It changes the button behavior according to iAppointmentId value.
  #
  # Also, before displaying the form itself (used either for adding or editing records),
  # it configures the internal buttons available on the top tool bar (print or issue receipt).
  #
  js_method :process_slot_click, <<-JS
    function( sYear, sMonth, sDay, sHour, sMins, iAppointmentId, iReceiptId ) {
// XXX DEBUG
//      console.log( 'This was called from elsewhere: ' + sYear + '-' + sMonth + '-' + sDay + ', ' + sHour + ':' + sMins + ", appointment ID=" + iAppointmentId );

      if ( iAppointmentId > 0 ) {                   // *** EDIT ***
        this.loadNetzkeComponent( {
          name: "edit_form",
          params: { record_id: iAppointmentId },    // FIXME Either deliver_component is not invoked or it seems to ignore the record_id parameter!
          callback: function(win) {                 // Workaround: manually loading the record with netzkeLoad (netzke_0 is the automatic name given to the first child component)  
            var cmp = win.getChildNetzkeComponent('netzke_0');
            var frm = cmp.getForm();
            var f = frm.findField('patient__get_full_name');
            f.setReadonlyMode(true);                // (only DragNDrop will allow slot patient change when no receipt has been issued yet)
            f = frm.findField('date_schedule');
            f.setReadonlyMode(true);                // (same as above)
            f = frm.findField('is_receipt_delivered');
            f.setReadonlyMode( iReceiptId < 1 );
            cmp.netzkeLoad( {id: iAppointmentId} );
                                                    // Disable unusable actions before displaying the component
            cmp.actions.managePatient.setDisabled( false );
            cmp.actions.reportPdf.setDisabled( iReceiptId == 0 );
            cmp.actions.reportPdfCopy.setDisabled( iReceiptId == 0 );
            cmp.actions.issueReceipt.setDisabled( iReceiptId > 0 );
                                                    // Cache iReceiptId value inside reportPdf action object for ease of retrieval:
            cmp.actions.reportPdf.receiptId = iReceiptId;

            // [Steve, 20130201] Note that since netzkeLoad() is asynch, we use the
            // cached iReceiptId value to reconfigure the component even before the Datastore
            // is updated.
            win.show();
          },
          scope: this
        } );
      }

      else {                                        // *** CREATE ***
        this.loadNetzkeComponent( {
          name: "add_form",
          callback: function(win) {
            var dtSchedule = new Date( sYear, sMonth - 1, sDay, sHour, sMins );
            var cmp = win.getChildNetzkeComponent('netzke_0');
            var frm = cmp.getForm();
            frm.setValues( {'date_schedule': dtSchedule} );
            var f = frm.findField('date_schedule');
            f.setReadonlyMode(true);
                                                    // Disable unusable actions before displaying the component
            cmp.actions.reportPdf.setDisabled( true );
            cmp.actions.reportPdfCopy.setDisabled( true );
            cmp.actions.issueReceipt.setDisabled( true );
                                                    // Reset cached iReceiptId value inside reportPdf action object:
            cmp.actions.reportPdf.receiptId = 0;
            win.show();

            win.on( 'close', function() {
              if ( win.closeRes === "ok" ) {        // Refresh the planner week, since we may have filled another slot
                this.updateFilteringScope('');      // This will either use Date.today or the one stored into the component session
              }
            }, this);
            
          },
          scope: this
        } );
      }
    }  
  JS
  # ---------------------------------------------------------------------------


  # Endpoint for refreshing the "global" data scope of the grid on the server-side component
  # (simply by updating the component session field used as variable parameter).
  #
  # == Params (either are facultative)
  # - filtering_date_start : an ISO-formatted (Y-m-d) date with which the grid scope can be updated
  # - filtering_date_end : as above, but for the ending-date of the range
  #
  endpoint :update_filtering_scope do |params|
# DEBUG
#    logger.debug( "\r\n--- WeekPlannerPanel::update_filtering_scope( #{params.inspect} ) CALLED" )
    curr_date = params.nil? || params.empty? ? nil : params[ PlannerCommandPanel::FILTERING_DATE_CMP_SYM ]
#    logger.debug( "curr_date: '#{curr_date.inspect}' from params" )
                                                    # No params or params empty? Use the component_session:
    if curr_date.nil? || curr_date.empty?
      component_session[PlannerCommandPanel::FILTERING_DATE_CMP_SYM] ||= Date.today.strftime(AGEX_FILTER_DATE_FORMAT_SQL)
      curr_date = component_session[PlannerCommandPanel::FILTERING_DATE_CMP_SYM].kind_of?( String ) ?
                  Date.parse( component_session[PlannerCommandPanel::FILTERING_DATE_CMP_SYM] ) :
                  component_session[PlannerCommandPanel::FILTERING_DATE_CMP_SYM]
    else                                            # With params, update the component_session:
      curr_date = Date.parse( curr_date ) if curr_date.kind_of?( String )
      component_session[PlannerCommandPanel::FILTERING_DATE_CMP_SYM] = curr_date
    end
# DEBUG
#    logger.debug( "curr_date: '#{curr_date.inspect}', after refresh\r\n" )
                                                    # == DATA Retrieval for the currently selected week:
    appointments = Appointment.find_all_week_appointments( curr_date )
    component_session[:appointments] = appointments.collect{ |record|
      record.serializable_hash.merge(
        'patient' => record.patient.serializable_hash,
        'receipt' => record.receipt.nil? ? nil : record.receipt.serializable_hash
      )
    }

    schedules = Schedule.find_all_week_schedules( curr_date, true ) # exclude_is_done: true
    component_session[:schedules] = schedules.collect{ |record|
      record.serializable_hash.merge( 'patient' => record.patient.serializable_hash )
    }
# DEBUG
#    puts "\r\n--- update_filtering_scope: #{curr_date.to_s}"
#    puts "    Schedules:    #{component_session[:schedules].inspect}"
#    puts "    Appointments: #{component_session[:appointments].inspect}"
                                                    # The following will the invoke PlannerGrid.updaPlannerRange() on the client-side:
    {
      :planner_grid => {
        :update_planner_range => {
          :week_start   => Schedule.get_week_start( curr_date ),
          :schedules    => component_session[:schedules],
          :appointments => component_session[:appointments]
        }
      }
    }
  end
  # ---------------------------------------------------------------------------
end
