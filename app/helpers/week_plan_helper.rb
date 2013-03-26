# encoding: utf-8

module WeekPlanHelper

  # Drag'n'drop support alias (enables to check directly the value instead of making a direct compare to the Hash value)
  #
  DRAG_N_DROP_GLOBAL_SWITCH = AGEX_FEATURES[ :enable_drag_n_drop_support ]


  # Get schedule cell special CSS style class, depending on current (processing) date.
  # curr_date : Date instance for extracting the current date
  # is_curr_app_receipt_issued : Must be true if currently processed appointment has already issued the receipt
  # is_curr_app_receipt_issued : Must be true if currently processed appointment has an issued & delivered receipt
  #
  def get_schedule_cell_style( curr_date, is_curr_app_receipt_issued = false, is_curr_app_receipt_delivered = false )
    if ( curr_date != Date.today && is_curr_app_receipt_delivered )
      'schedule-receipt-sent'
    elsif ( curr_date == Date.today && is_curr_app_receipt_delivered )
      'schedule-receipt-sent-today'
    elsif ( curr_date != Date.today && is_curr_app_receipt_issued )
      'schedule-receipt-done'
    elsif ( curr_date == Date.today && is_curr_app_receipt_issued )
      'schedule-receipt-done-today'
    elsif ( curr_date == Date.today )
      'schedule-today'
    else
      nil
    end
  end
  # ---------------------------------------------------------------------------


  # Builds up HTML table for displaying a week's schedule based on a
  # specified date (defaults to today), starting from the beginning of the
  # week.
  # Supports drag'n'drop, but only if the global switch of the framework has been
  # enabled and the currently logged-in user is allowed to modify the weekly schedule.
  #
  # curr_date : Date instance for extracting current week;
  # schedules : a collection of all the Schedule notes of the current week.
  # appointments_cache : a collection of all the Appointment instances of the current week.
  #
  def build_week_plan_table( curr_date, schedules, appointments_cache )
    sOut = "    \r\n"                               # (Add CR+LF for each table row to improve generated source readibility)

    # This will contain all the lookup tables for DOM IDs, Appointment IDs, and empty-date place-holders' IDs
    # and will be filled during the construction of the table with several arrays, one for each cross-reference needed:
    # (Only used when drag'n'drop support is enabled) 
    dom_xref_hash = {
      :drag_appointment_ids  => [],
      :drag_appointment_doms => [],
      :drag_schedule_ids  => [],
      :drag_schedule_doms => [],
      :drop_date_schedules     => [],
      :drop_date_schedule_doms => []
    }

    sOut << content_tag( :thead, table_header_for_week( curr_date ) )
    sOut << content_tag( :tbody, table_rows_for_week( curr_date, schedules, appointments_cache, dom_xref_hash ) )
    sOut << "    \r\n"                              # (Add CR+LF for each table row to improve generated source readibility)
                                                    # Ugly but working: store in the session the X-ref. tables of the drag'n'drop DOM IDs:
    current_user = LeUser.find(session[:le_user_id])
    session["#{controller_name()}_dom_xref_hash".to_sym] = dom_xref_hash if DRAG_N_DROP_GLOBAL_SWITCH && current_user && current_user.can_do(:appointments, :update)
    return sOut
  end
  # ---------------------------------------------------------------------------



  # Builds up HTML table headers for displaying a week's schedule based on a
  # specified date (defaults to today), starting from the beginning of the
  # week.
  # curr_date : Date instance for extracting the current day
  def table_header_for_week( curr_date = Date.today )
    sOut = "\r\n"                                   # (Add CR+LF for each table row to improve generated source readibility)
    dt_start = Schedule.get_week_start( curr_date )

    dt_start.step(dt_start+5, 1) { |d|
      header_text = "" << d.day.to_s << "/" << d.month.to_s << "<br/>" << h(Schedule.long_day_name( d.cwday ))
      sOut << "    #{content_tag( :th, header_text, :class => get_schedule_cell_style( d ) )}\r\n"
    }
    sOut << "    #{content_tag( :th, h(Schedule.long_day_name(7)), :class => 'schedule-notes' )}\r\n"

    return content_tag( :tr, sOut, :class => 'schedule-header' )
  end
  # ---------------------------------------------------------------------------


  # Returns the Droppable JS text to be included in a droppable DOM Id.
  #
  def get_droppable_script( droppable_dom_id )
    text = <<-END_SRC
        Droppables.add('#{droppable_dom_id}', {
          onDrop: function(dragged, dropped, event) {
            new Ajax.Request("/week_plan/move/?from=" + dragged.id + "&to=" + dropped.id, {
              asynchronous: true, evalScripts: true, method: "post",
              onFailure: function(response) {
                  alert('Server Response FAIL!');
              }
            });
            return false;
          }
        });
    END_SRC
    text
  end
  # ---------------------------------------------------------------------------

  # Returns the Draggable JS text to be included in a draggable DOM Id.
  #
  def get_draggable_script( draggable_dom_id )
    text = <<-END_SRC
        new Draggable('#{draggable_dom_id}', { revert: 'failure', scroll: window });
    END_SRC
    text
  end
  # ---------------------------------------------------------------------------

  # Returns true if the specified current_datetime is a few seconds away from current System date & time
  #
  def has_beeen_updated_recently?( update_time )
    now = Time.now.utc
    ( (! update_time.nil?) && (update_time.year == now.year) && (update_time.month == now.month) && (update_time.day == now.day) &&
      (update_time.hour == now.hour) && (update_time.min == now.min) && ((now.sec - update_time.sec).abs < 7) )
  end
  # ---------------------------------------------------------------------------

  # Returns the highlight FX JS text to be included in the specified DOM Id
  # if the specified DateTime instance has a value only a few seconds away from current DateTime.
  #
  def get_highlight_script_if_recently_updated( dom_id, update_time )
    text = <<-END_SRC
          Effect.Pulsate('#{dom_id}');
    END_SRC
    has_beeen_updated_recently?( update_time ) ? text : ''
  end
  # ---------------------------------------------------------------------------

  # Builds up a DOM ID using the prefix and a target_datetime string
  #
  def get_unique_dom_id( prefix, target_datetime )
    "#{prefix}_#{target_datetime}".gsub(/[òàèùçé^!"'£$%&?.,;:§°<>]/,'').gsub(/[\s|]/,'_').gsub(/[\\\/=]/,'-')
  end
  # ---------------------------------------------------------------------------


  # Builds a single HTML table row for displaying a single appointments line in 
  # current week's schedule, computing the week range with the same algorithm used
  # in table_header_for_week.
  #
  # Each table cell will be built with both drag'n'drop functionality (if enabled)
  # and with a link to either show or edit the cell contents - but only if the current user
  # stored in the session can actually carry out the action involved.
  #
  # curr_date : Date instance for extracting current week
  # start_time : DateTime instance representing work shift starting time
  # offset_min : Integer offset in minutes from starting time
  # schedule  : schedule instance; it can be nil if the "schedule notes slot" is assumed to be empty for this row.
  # appointments_cache : a collection of all the Appointment instances of the current week.
  # dom_xref_hash : Hash containing all the lookup tables for DOM IDs, Appointment IDs, and empty-date place-holders' IDs.
  #                The hash will be filled during the construction of the table with several arrays, one for each cross-reference needed. 
  #
  def table_row_for_week( curr_date, start_time, offset_min, schedule, appointments_cache, dom_xref_hash )
    current_user = LeUser.find(session[:le_user_id])
    curr_tot_min = start_time.hour * 60 + start_time.min + offset_min
    curr_hour_digit = curr_tot_min / 60
    curr_min_digit = curr_tot_min % 60
    sTemp = "" << start_time.year.to_s << "-" << "%02u" % start_time.month.to_s << "-" << 
            "%02u" % start_time.day.to_s << " " <<
            "%02u" % curr_hour_digit.to_s << ":" << "%02u" % curr_min_digit.to_s << ":00"
    curr_hour = DateTime.parse(sTemp)

    sOut = "\r\n"                                   # (Add CR+LF for each table row to improve generated source readibility)
    dt_start = Schedule.get_week_start( curr_date )

                                                    # -- DAY CELL SLOT: add a table cell to the row for each working day:
    dt_start.step(dt_start+5, 1) { |d|
      curr_name = ""
      curr_updated_on = nil
      curr_id = 0
      curr_is_receipt_issued = false
      s_target_datetime = Schedule.format_datetime_coordinates_for_mysql_param( d, curr_hour )

      for app in appointments_cache
        if s_target_datetime == Schedule.format_datetime_for_mysql_param( app.date_schedule )
          curr_name = app.get_full_name
          curr_id = app.id
          curr_updated_on = app.updated_on
          curr_is_payed = app.is_payed?
          curr_is_receipt_issued = app.is_receipt_issued
          curr_is_receipt_delivered = app.is_receipt_delivered
          break
        end
      end
                                                    # Build-up basic link to insert into the cell:
      table_data = ( curr_is_payed ? content_tag(:div, '', :class => 'schedule-payed-img') : '' ) +
                   link_to_unless(
                            ( current_user.nil? ||
                              !( curr_name.blank? ? current_user.can_do(:appointments, :create) :
                                                    current_user.can_do(:appointments, :show)
                               )
                            ),
                            "%02u" % curr_hour_digit.to_s << ":" << "%02u" % curr_min_digit.to_s,
                            ( curr_name.blank? ? edit_appointments_path( :id => curr_id, :curr_time => s_target_datetime ) :
                                                 show_appointments_path( :id => curr_id, :curr_time => s_target_datetime )
                            )
                    ) +
                    "<br/>" + h( curr_name )
                                                    # Make table cell data draggable or droppable, if we can:
      if  curr_name.blank?                          # 'DROP'-appointment type:
        div_id = get_unique_dom_id( 'dropapp', s_target_datetime )
        table_data = content_tag( :div, table_data, :id => div_id ) + "\r\n"
        if DRAG_N_DROP_GLOBAL_SWITCH && current_user && current_user.can_do(:appointments, :update)
          table_data << content_tag( :script, get_droppable_script(div_id), :type => "text/javascript" ) + "\r\n"
          dom_xref_hash[:drop_date_schedules]     << s_target_datetime
          dom_xref_hash[:drop_date_schedule_doms] << div_id
        end
                                                    # 'DRAG'-appointment type:
      elsif ! curr_is_receipt_issued
        div_id = get_unique_dom_id( 'dragapp', s_target_datetime )
        table_data = content_tag( :div, table_data, :id => div_id, :style => "width:100%; height:4em; background-color:inherit;" ) + "\r\n"
        if DRAG_N_DROP_GLOBAL_SWITCH && current_user && current_user.can_do(:appointments, :update)
          table_data << content_tag( :script, get_draggable_script(div_id) + get_highlight_script_if_recently_updated(div_id, curr_updated_on), :type => "text/javascript" ) + "\r\n"
          dom_xref_hash[:drag_appointment_ids]  << curr_id
          dom_xref_hash[:drag_appointment_doms] << div_id
        end
                                                    # 'FIXED'-appointment type:
      else
        div_id = get_unique_dom_id( 'app', s_target_datetime )
        script_text = get_highlight_script_if_recently_updated( div_id, curr_updated_on )
        table_data = content_tag( :div, table_data, :id => div_id ) + "\r\n"
        unless script_text.blank?
          table_data << content_tag( :script, script_text, :type => "text/javascript" ) + "\r\n"
        end
      end
                                                    # Encapsulate data in table cell:
      sOut << "    #{content_tag( :td, table_data, :class => get_schedule_cell_style(d, curr_is_receipt_issued, curr_is_receipt_delivered) )}\r\n" 
    }

                                                    # -- SCHEDULE NOTES SLOT: add another table cell at the end of the row:
    s_target_datetime = Schedule.format_datetime_coordinates_for_mysql_param( dt_start+6, curr_hour )
    schedule_notes_slot = ''

    if schedule.nil?                                # 'DROP'-slot type:
        div_id = get_unique_dom_id( 'dropslot', s_target_datetime )
        schedule_notes_slot = content_tag( :div, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;', :id => div_id ) + "\r\n"
        if DRAG_N_DROP_GLOBAL_SWITCH && current_user && current_user.can_do(:appointments, :update)
          schedule_notes_slot << content_tag( :script, get_droppable_script(div_id), :type => "text/javascript" ) + "\r\n"
          dom_xref_hash[:drop_date_schedules]     << ''       # leave schedule date blank for empty side slots that are drop targets
          dom_xref_hash[:drop_date_schedule_doms] << div_id
      end
                                                    # 'DRAG'-slot type:
    elsif schedule.must_insert? and (! schedule.is_done?)
        div_id = get_unique_dom_id( 'dragslot', s_target_datetime )
        schedule_notes_slot = content_tag( :div, schedule.get_full_description(), :id => div_id, :style => "width:100%; height:4em; background-color:inherit;" ) + "\r\n"
        if DRAG_N_DROP_GLOBAL_SWITCH && current_user && current_user.can_do(:appointments, :update)
          schedule_notes_slot << content_tag( :script, get_draggable_script(div_id) + get_highlight_script_if_recently_updated(div_id, schedule.updated_on), :type => "text/javascript" ) + "\r\n"
          dom_xref_hash[:drag_schedule_ids]  << schedule.id
          dom_xref_hash[:drag_schedule_doms] << div_id
        end
                                                    # 'FIXED'-slot type:
    else
      div_id = get_unique_dom_id( 'slot', s_target_datetime )
      schedule_notes_slot = content_tag( :div, schedule.get_full_description(), :id => div_id ) + "\r\n"
      script_text = get_highlight_script_if_recently_updated( div_id, schedule.updated_on )
      unless script_text.blank?
        schedule_notes_slot << content_tag( :script, script_text, :type => "text/javascript" ) + "\r\n" 
      end
    end
    sOut << "    #{content_tag( :td, schedule_notes_slot, :class => 'schedule-notes' )}\r\n"

    return content_tag( :tr, sOut, :class => 'schedule-row' )
  end
  # ---------------------------------------------------------------------------



  # Builds an HTML table for displaying current week's appointment schedule.
  # 
  # curr_date : Date instance for extracting current week;
  # schedules : a collection of all the Schedule notes of the current week.
  # appointments_cache : a collection of all the Appointment instances of the current week.
  # dom_xref_hash : Hash containing all the lookup tables for DOM IDs, Appointment IDs, and empty-date place-holders' IDs.
  #                The hash will be filled during the construction of the table with several arrays, one for each cross-reference needed.
  # 
  def table_rows_for_week( curr_date, schedules, appointments_cache, dom_xref_hash )
    sOut = ""
    app_length = AppParameterCustomizations.get_appointment_length_in_mins()

                                        # Morning (AM) schedule:
    app_result = AppParameterCustomizations.get_morning_schedule()
    am_start_time = app_result[:start_time]
    am_total_appointments = app_result[:total_appointments]
    throw( "Missing AppParameter configuration parameter values for default AM schedule size! Check database app_parameter table." ) if am_start_time.nil? || am_total_appointments.nil?
    
    n = 0
    while n < am_total_appointments do
      schedule = nil
      if (schedules != nil) && (schedules.length > n)
        schedule = schedules[n]
      end
      sOut << table_row_for_week( curr_date, am_start_time, app_length * n, schedule, appointments_cache, dom_xref_hash )
      n = n + 1
    end
                                        # Lunch break:
    sOut << "  #{content_tag(:tr, '', :class => 'schedule-gap')}\r\n"

                                        # Noon (PM) schedule:
    app_result = AppParameterCustomizations.get_noon_schedule()
    pm_start_time = app_result[:start_time]
    pm_total_appointments = app_result[:total_appointments]
    throw( "Missing AppParameter configuration parameter values for default PM schedule size! Check database app_parameter table." ) if pm_start_time.nil? || pm_total_appointments.nil?

    n = 0
    while n < pm_total_appointments do
      schedule = nil
      if (schedules != nil) && (schedules.length > am_total_appointments + n)
        schedule = schedules[am_total_appointments + n]
      end
      sOut << table_row_for_week( curr_date, pm_start_time, app_length * n, schedule, appointments_cache, dom_xref_hash )
      n = n + 1
    end

    return sOut
  end
  # ---------------------------------------------------------------------------
end
