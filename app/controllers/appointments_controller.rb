class AppointmentsController < ApplicationController

  # Require authorization before invoking any of this controller's actions:
  before_filter :authorize


  # Default action.
  #
  # == Params:
  #
  # - <tt>:date_from_lookup</tt>, <tt>:date_to_lookup</tt> =>
  #   The date range for which the analysis must be performed.
  #
  # - <tt>:date_schedule</tt> || <tt>:curr_date</tt> =>
  #   The current date inside the week to be displayed. This is used only if no other range is supplied.
  #
  def index
# DEBUG
#    logger.debug( "\r\n\r\n---[ #{controller_name()}.index ] ---" )
#    logger.debug( "Params: #{params.inspect()}" )
    ap = AppParameter.get_parameter_row_for( :appointments )
    @max_view_height = ap.get_view_height()

    if ( params[:date_from_lookup].blank? && params[:date_schedule].blank? && params[:curr_date].blank? )
                                                    # Having the parameters, apply the resolution and the radius backwards:
      start_date = DateTime.now.strftime( ap.get_filtering_resolution )
                                                    # Set the (default) parameters for the scope configuration: (actual used value will be stored inside component_session[])
      @filtering_date_start  = ( Date.parse( start_date ) - ap.get_filtering_radius ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
      @filtering_date_end    = ( Date.parse( start_date ) + ap.get_filtering_radius ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
    else
      begin
        curr_date = Date.parse params[:date_from_lookup] || params[:date_schedule] || params[:curr_date]
      rescue
        logger.warn("**[W]** - #{controller_name()}.index(): Warning: invalid date specified as paramaters! (params=#{params.inspect})")
        curr_date = Date.today
      end
                                                    # Compute actual date range for the SQL data extraction query:
      @filtering_date_start = Schedule.get_week_start( curr_date ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
      @filtering_date_end = params[:date_to_lookup] || Schedule.get_week_end( curr_date ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
      # [20130212] We must use the AGEX_FILTER_DATE_FORMAT_SQL for the filtering dates used by
      # the custom Netzke component for the date filtering, because the result text from the
      # method Schedule.get_week_start/end_for_mysql_param() uses a DateTime instance instead of a simple Date
      # (used inside the FilteringDateRangePanel)
    end

# DEBUG
#    logger.debug( "@filtering_date_start: #{@filtering_date_start.inspect()}" )
#    logger.debug( "@filtering_date_end:   #{@filtering_date_end.inspect()}" )
    @context_title = I18n.t(:appointments_list, {:scope=>[:patient]})
  end
  # ---------------------------------------------------------------------------



  # Issues the receipt, updating also all associated Appointment instances.
  #
  # Since version 2.5 this action works for creating both single and multi-appointment receipts.
  #
  # The transaction will fall back for multi-appointment receipts if *any* of the selected appointments
  # has already an issued receipt associated with it.
  #
  # ==Params:
  # - +id+ => Appointment ID for which the Receipt must be issued.
  # - +ids+ => either an Array of Appointment IDs or a String of IDs concatenated by ',', for which the Receipt must be issued. Used only when params[:id] is not specified
  # - +date_receipt+ : chosen Date for the receipt; can be +nil+ to use the current date.
  # - +patient_id+   : Patient id chosen for the receipt. When missing Appointment.patient_id will be used, assuming either one of :id or :ids parameters are specified and valid.
  #
  def issue_receipt
    return if request.xhr?                          # (This is not supposed to be used with an Ajax call)
# DEBUG
    logger.debug "\r\n!! ----- AppointmentsController::issue_receipt() -----"
    logger.debug "issue_receipt: params #{params.inspect}"
                                                    # Parse params:
    id_list = []
                                                    # Collect all the Appointment IDs we have to process into a single array:
    if params[:id].to_i > 0                         # Single-appointment Receipt, typical case
      id_list << params[:id]

    elsif params[:data]                             # Multi-appointment Receipt, typical case
      id_list = ActiveSupport::JSON.decode( params[:data] )

    elsif params[:ids].instance_of?( Array )        # (Backward-compatibility case)
      id_list = params[:ids]

    elsif params[:ids].instance_of?( String )       # (Backward-compatibility case)
      id_list = params[:ids].split(',').compact.uniq.sort
    end

    is_ok = (id_list.size > 0)                      # set OK status depending on whether we have any IDs for retrieval or not
    msg = '-- Unexpected error condition! --'       # set a default flash msg to enhance the scope of the variable
                                                    # Get an array of all the rows to be updated
    appointments = nil
    begin
      appointments = Appointment.where( :id => id_list )
    rescue
      raise ArgumentError, "AppointmentsController::issue_receipt(): no valid ID(s) found inside data parameter!", caller
    end
# DEBUG
    logger.debug "AppointmentsController::issue_receipt(): id list: #{id_list.inspect}"

    if is_ok && (appointments.size > 0)             # Any valid row instances found and ready to be processed? Prepare data for the creation of a new receipt:
      receipt = Receipt.new( params[:receipt] )
      receipt.patient_id = appointments[0].patient_id unless (receipt.patient_id.to_i > 0)
      receipt.additional_notes = ""
                                                    # Init collected values:
      receipt.price = 0
      appointments_list = []
      payed_appointments = []
      all_is_payed = true
                                                    # Compute collect price and "all_is_payed" flag
      appointments.each { |appointment|
        receipt.additional_notes += appointment.additional_notes + "\r\n" if appointment.additional_notes
        receipt.price += appointment.price
        all_is_payed = all_is_payed && appointment.is_payed
        payed_appointments << appointment.get_date_schedule if appointment.is_payed
        appointments_list << appointment.get_date_schedule
      }
      receipt.is_payed = all_is_payed
      receipt.notes = "#{I18n.t(:appointments_payed, {:scope=>[:receipt]})}: #{payed_appointments.join(", ")}" if payed_appointments.size > 0
      receipt.additional_notes = receipt.additional_notes +
                                 "\r\n#{I18n.t(:invoiced_appointments, {:scope=>[:receipt]})}: #{appointments_list.join(", ")}" if appointments_list.size > 1
                                                    # Preset additional values
      receipt.preset_default_values( :date_receipt => receipt.date_receipt, :patient_id => receipt.patient_id )
# DEBUG
      logger.debug "AppointmentsController::issue_receipt(): receipt: #{receipt.inspect}"

      begin
        ActiveRecord::Base.transaction do           # ----- START TRANSACTION -----
          if receipt.save                           # Receipt save (possibly) sucessful?...
            appointments.each do |appointment|      # ...Iterate on all appointments:
              if !appointment.is_receipt_issued?    # Update currently processed appointment instance:    
                appointment.receipt_id = receipt.id # No receipt issued yet? (This should be the norm) => Update receipt ID
                unless appointment.save
                  log_error("in issue_receipt() during appointment update - APPOINTMENT: " << appointment.inspect)
                  msg = I18n.t(:something_went_wrong)
                  log_info('Rolling back transaction...')
                  is_ok = false
                  raise ActiveRecord::Rollback
                end
              else
                log_error("issue_receipt(): Receipt already issued! - APPOINTMENT: #{appointment.inspect}\r\nSome of the selected IDs had already an issued Receipt and this should (normally) never occur when the standard selection view is used.")
                msg = I18n.t(:something_went_wrong)
                log_info('Rolling back transaction...')
                is_ok = false
                raise ActiveRecord::Rollback
              end
            end                                     # (end of loop)
          else                                      # Receipt save failure!
            log_error( "in issue_receipt() during receipt save - RECEIPT: " << receipt.inspect )
            msg = I18n.t(:something_went_wrong)
            log_info('Rolling back transaction...')
            is_ok = false
            raise ActiveRecord::Rollback
          end
        end

      rescue                                        # ----- END TRANSACTION -----
        is_ok = false
        log_error('executing transaction rollback...')
        msg ||= $!.to_s
        msg = "#{msg} #{I18n.t(:transaction_cancelled)}"
      end
                                                    # Set an O-K message only if everything went as expected:
      msg = I18n.t(:new_receipt_issued, {:scope=>[:receipt]}) + " (#{receipt.get_receipt_header()})" if is_ok
    else                                            # Appointment instance list was empty?
      if ! is_ok                                    # User didn't select anything:
        msg = I18n.t(:no_selection_receipt_not_issued, {:scope=>[:receipt]})
      else                                          # Something was selected, but nothing was retrieved:
        log_error( "issue_receipt(): An error as occurred while retrieving some of the selected appointment data:\r\nEmpty appointment instance list - PARAMS: " << params.inspect )
        msg = I18n.t(:something_went_wrong)
      end
    end
                                                    # Set the flash message and set the redirect:
    flash[:notice] = msg
    redirect_to( (appointments.size == 0) || (! is_ok) ? week_plan_path() : receipts_path() )
  end
  # ---------------------------------------------------------------------------

end
