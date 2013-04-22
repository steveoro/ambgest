# encoding: utf-8

class WeekPlanController < ApplicationController
  require 'common/format'
  require 'ruport'
  require 'income_analysis_layout'

  # Require authorization before invoking any of this controller's actions:
  before_filter :authorize


  # Default action.
  #
  # == Params:
  #
  # - <tt>:date_schedule</tt> || <tt>:curr_date</tt> =>
  #   The current date inside the week to be displayed.
  #
  def index
    logger.debug( "\r\n\r\n---[ #{controller_name()}.index ] ---" )
    logger.debug( "Params: #{params.inspect()}" )

    if ( params[:date_schedule].blank? && params[:curr_date].blank? )
      @filtering_date_start  = nil
      @filtering_date_end    = nil
    else
      begin
        curr_date = Date.parse params[:date_schedule] || params[:curr_date]
      rescue
        logger.warn("**[W]** - #{controller_name()}.index(): Warning: invalid date specified as paramaters! (params=#{params.inspect})")
        curr_date = Date.today
      end
                                                    # Compute actual date range for the SQL data extraction query:
      @filtering_date_start = Schedule.get_week_start( curr_date ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
      @filtering_date_end   = Schedule.get_week_end( curr_date ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
      # [20130212] We must use the AGEX_FILTER_DATE_FORMAT_SQL for the filtering dates used by
      # the custom Netzke component for the date filtering, because the result text from the
      # method Schedule.get_week_start/end_for_mysql_param() uses a DateTime instance instead of a simple Date
      # (used inside the FilteringDateRangePanel)
    end

# DEBUG
    logger.debug( "@filtering_date_start: #{@filtering_date_start.inspect()}" )
    logger.debug( "@filtering_date_end:   #{@filtering_date_end.inspect()}" )
  end
  # ---------------------------------------------------------------------------


  # Show current income based on the date parameters specified, either a range or a current date.
  # If no current date parameter is set, just computes the current week's
  # schedule.
  #
  # == Params:
  #
  # - <tt>:date_from_lookup</tt>, <tt>:date_to_lookup</tt> =>
  #   The date range for which the analysis must be performed.
  #
  # - <tt>:date_schedule</tt> || <tt>:curr_date</tt> =>
  #   The current date inside the week to be displayed. This is used only if no other range is supplied.
  #
  def income_analysis()
# DEBUG
#    logger.debug( "\r\n\r\n---[ #{controller_name()}.income_analysis ] ---" ) if DEBUG_VERBOSE
#    logger.debug( "Params: #{params.inspect()}" ) if DEBUG_VERBOSE

    prepare_income_analysis_data()

    # Setting this to true will write the current filtering parameters to the filtering
    # panel of the view, instead of restoring the (previously) session-cached values.
    @override_filtering = true
  end
  # ---------------------------------------------------------------------------


  # Outputs PDF equvalent of the "income_analysis" view.
  #
  # == Params:
  #
  # - <tt>:date_from_lookup</tt>, <tt>:date_to_lookup</tt> =>
  #   The date range for which the analysis must be performed.
  #
  # - <tt>:date_schedule</tt> || <tt>:curr_date</tt> =>
  #   The current date inside the week to be displayed. This is used only if no other range is supplied.
  #
  def report_detail
    logger.debug( "\r\n\r\n---[ #{controller_name()}.report_detail ] ---" ) if DEBUG_VERBOSE
    logger.debug( "Params: #{params.inspect()}" ) if DEBUG_VERBOSE

    prepare_income_analysis_data()

    # XXX After this point we *must* have already defined:
    # - @receipts_per_week
    # - @appointments_per_receipt
    # - @filters_status
    # - @date_schedule (original date_schedule param from the request)
    # - @filtering_date_start (adjusted to wider range for the analysis chart)
    # - @filtering_date_end (computed from date_schedule and fixed to the end of the week of date_schedule)
                                                    # Re-fix filtering date start using original request:
    @filtering_date_start = Schedule.get_week_start_for_mysql_param( @date_schedule )
    currency_name = I18n.t(:currency_verbose, {:scope=>[:receipt]})

    column_names = [
      :receipt, :base_amount, :items_to_be_divested, :net_taxable,
      :entries_percentage, :tot_additional_charges, :gross_amount, 
      :receipt_delivered, :is_payed
    ]

    label_hash = {                                  # == Init LABELS ==
      :report_created_on    => I18n.t(:report_created_on, {:scope=>[:account_row]}),
      :filtering_label      => I18n.t(:filtering_label, {:scope=>[:account_row]}),
      :grouping_total_label => I18n.t(:grouping_total_label, {:scope=>[:account_row]}),
      :meta_info_subject    => "Ambgest3 Income Analysis",
      :meta_info_keywords   => "Ambgest3,Income analysis,AgeX5,Receipt analysis"
    }

    column_names.each { |e|
      label_hash[e.to_sym] = I18n.t( e.to_sym, {:scope=>[:income_analysis]} ) unless label_hash[e.to_sym]
    }

                                                    # == DATA Collection == (Data must be converted under a common currency)
    report_data_hash = prepare_report_data_hash( column_names, currency_name )

                                                    # == OPTIONS setup + RENDERING phase ==
    filename = create_unique_filename(
      "#{I18n.t(:receipts_list_file_name, {:scope=>[:income_analysis]})}_#{@filters_status.gsub(/-/, '').gsub(' ... ', '-')}"
    ) + '.pdf'

    options = {
      :report_title         => "#{I18n.t(:receipts_list_during_period, {:scope=>[:income_analysis]})}: #{@filters_status}",
      :date_from            => @filtering_date_start,
      :date_to              => @filtering_date_end,
      :currency_name        => currency_name,

      :label_hash           => label_hash,
      :data_table           => report_data_hash[:data_table],
      :summary_rows         => report_data_hash[:summary_rows],
      :grouping_total       => report_data_hash[:grouping_total]
    }
                                                    # == Render layout & send data:
    send_data(
        IncomeAnalysisLayout.render( options ),
        :type => 'application/pdf',
        :filename => filename
    )
  end
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------


################################### WIP down below start #####################à


  # Moves either an Appointment or a Schedule note from a date to another or to an empty slot, via AJAX request.
  #
  def move()
    logger.debug( "\r\n\r\n---[ #{controller_name()}.move ] ---" ) if DEBUG_VERBOSE
                                                    # == Ajax update (POST):
    if request.xhr?                                 # POST/Ajax call issued? Retrieve X-reference hash and parse the drag move:
      dom_xref_hash = session["#{controller_name()}_dom_xref_hash".to_sym]
      parse_drag_move_operation(params[:from], params[:to], dom_xref_hash ) if ( dom_xref_hash && params[:from] && params[:to] )
      manage()

    else                                            # == Simple HTML render (GET):
      flash[:warning] = as_('Nothing to do.')
      redirect_to main_week_plan_path()
    end 
  end
  # ---------------------------------------------------------------------------
  #++


  private


  # Debug verbose toggle flag
  DEBUG_VERBOSE = true


  def prepare_income_analysis_data()
    if ( params[:date_from_lookup].blank? && params[:date_schedule].blank? && params[:curr_date].blank? )
      curr_date = Date.today
    else
      begin
        curr_date = Date.parse params[:date_from_lookup] || params[:date_schedule] || params[:curr_date]
      rescue
        logger.warn("**[W]** - prepare_income_analysis_data(): Warning: invalid date specified as paramaters! (params=#{params.inspect})")
        curr_date = Date.today
      end
      @date_schedule = curr_date
    end
                                                    # Compute actual date range for the SQL data extraction query:
    @filtering_date_start = Schedule.get_week_start_for_mysql_param( curr_date )
    @filtering_date_end   = params[:date_to_lookup] || Schedule.get_week_end_for_mysql_param( curr_date )
                                                    # Set a filtering label to be displayed in the report:
    @filters_status = @filtering_date_start[0..9] + " ... " + @filtering_date_end[0..9]

# DEBUG
#    logger.debug( "@filters_status: '#{@filters_status}'" )

    @receipts_per_week = Receipt.find_all_receipts_for( @filtering_date_start, @filtering_date_end )
    @appointments_per_receipt = {}
    @receipts_per_week.each { |receipt|
      @appointments_per_receipt[receipt.id] = Appointment.joins(:patient).where( :receipt_id => receipt.id )
    }
                                                    # Adjust filtering to 1 month just for the analysis chart:
    @filtering_date_start = Schedule.get_week_start_for_mysql_param( curr_date - 21 )
  end


  # Returns the data hash used to build the report_detail layout, using the already
  # defined (implicit) members:
  #
  # - @receipts_per_week
  # - @appointments_per_receipt
  # - @filters_status
  # - @date_schedule (original date_schedule param from the request)
  # - @filtering_date_start (adjusted to wider range for the analysis chart)
  # - @filtering_date_end (computed from date_schedule and fixed to the end of the week of date_schedule)
  #
  # == Parameters:
  #
  # - :column_names => Array of Symbols of the columns of the above table
  # - :currency_name => the String representing the currency name
  #
  # == Returns:
  #
  # - :data_table     => the resulting Ruport table used in the layout
  # - :summary_rows   => an Array of 2 row-arrays, containing the summarized totals
  #                      of data_table, formatted using the same column alignment
  # - :grouping_total => the grand total result obtained from the data loop
  #
  def prepare_report_data_hash( column_names, currency_name )
    grand_total = tot_to_be_payed = tot_base_price = tot_minus_costs = tot_plus_costs = tot_percentages = tot_net_price = tot_payed = 0.0
    tot_is_delivered = tot_is_payed = 0
    data_rows = []
                                                    # --- Receipt data LOOP: ---
    @receipts_per_week.each { |receipt|
      costs = receipt.get_additional_cost_totals
      net_price = receipt.net_price
      percentage_amount = receipt.account_percentage_amount
      tot_base_price += receipt.price
      tot_minus_costs += costs[:negative]
      tot_plus_costs += costs[:positive]
      tot_percentages += percentage_amount
      tot_net_price += net_price
      amount = net_price + percentage_amount + costs[:positive] - costs[:negative]
      receipt.is_payed? ? tot_payed += receipt.price.to_f : tot_to_be_payed += receipt.price.to_f
      tot_is_delivered += 1 if receipt.is_receipt_delivered?
      tot_is_payed     += 1 if receipt.is_payed?
                                                    # --- Receipt data row: ---
      data_rows << [
        ( receipt.is_payed? ? "<b>#{receipt.get_receipt_header}</b>" : receipt.get_receipt_header ),
        receipt.price,
        costs[:negative],
        net_price,
        percentage_amount,
        costs[:positive],
        ( receipt.is_payed? ? "<b>#{amount}</b>" : amount ),
        ( receipt.is_receipt_delivered? ? "[<b> X </b>]" : '[__]' ),
        ( receipt.is_payed? ? "[<b> X </b>]" : '[__]' )
      ]
                                                    # --- Appointment data sub-LOOP: ---
      unless ( @appointments_per_receipt[ receipt.id ].nil? || @appointments_per_receipt[ receipt.id ].size < 1 )
        data_rows << [
          '',
          "<color rgb='346842'><i>#{I18n.t(:invoiced_appointments,  {:scope=>[:income_analysis]})}</i></color>",
          '',
          '',
          "<color rgb='346842'><i>#{I18n.t(:patient__get_full_name,   {:scope=>[:appointment]})}</i></color>",
          "<color rgb='346842'><i>#{I18n.t(:appointment,  {:scope=>[:appointment]})}</i></color>",
          "<color rgb='346842'><i>#{I18n.t(:price_verbose,  {:scope=>[:receipt]})}</i></color>",
          '',
          "<color rgb='346842'><i>#{I18n.t(:is_payed,   {:scope=>[:appointment]})}</i></color>"
        ]

        tot_count = 0
        tot_appointments_payed = tot_appointments_amount = 0.0
        @appointments_per_receipt[ receipt.id ].each { |appointment|
          tot_count += 1
          tot_appointments_amount += appointment.price.to_f
          tot_appointments_payed += appointment.price.to_f if appointment.is_payed?
          appointment_verbose = appointment.get_verbose_name.split(' @ ')
                                                    # --- Appointment data row: ---
          data_rows << [
            '',
            '',
            '',
            '',
            appointment_verbose[0],
            appointment_verbose[1],
            appointment.price,
            '',
            ( appointment.is_payed? ? "[<b> X </b>]" : '[__]' )
          ]
        }
                                                    # --- Appointment summary row: ---
        data_rows << [
          '',
          '',
          '',
          '',
          '',
          "<color rgb='346842'><i>#{I18n.t(:subtotals, {:scope=>[:income_analysis]})}</i></color>",
          tot_appointments_amount,
          "<color rgb='346842'>#{I18n.t(:to_be_payed, {:scope=>[:receipt]})}:</color>\r\n#{tot_appointments_amount - tot_appointments_payed} #{currency_name}",
          "<color rgb='346842'><b>#{I18n.t(:payed, {:scope=>[:receipt]})}:</color>\r\n#{tot_appointments_payed} #{currency_name}</b>"
        ]
      end
                                                    # --- Empty separator row
      data_rows << [
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        ''
      ]
    }
                                                    # --- Receipt summary row: ---
    grand_total = tot_net_price + tot_percentages + tot_plus_costs - tot_minus_costs
    summary_rows = []
    summary_rows << [
      "<color rgb='00076d'><b><i>#{I18n.t(:totals, {:scope=>[:income_analysis]})}</i>:</color>\r\n(#{@receipts_per_week.count} #{I18n.t(:receipts, {:scope=>[:income_analysis]})})</b>",
      "<color rgb='00076d'><b>#{tot_base_price}</b></color>",
      "<color rgb='00076d'><b>#{tot_minus_costs}</b></color>",
      "<color rgb='00076d'><b>#{tot_net_price}</b></color>",
      "<color rgb='00076d'><b>#{tot_percentages}</b></color>",
      "<color rgb='00076d'><b>#{tot_plus_costs}</b></color>",
      "<color rgb='00076d'><b>#{grand_total}</b></color>",
      "<color rgb='00076d'><b>#{tot_is_delivered} / #{@receipts_per_week.count}</b></color>",
      "<color rgb='00076d'><b>#{tot_is_payed} / #{@receipts_per_week.count}</b></color>"
    ]
    summary_rows << [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      "<color rgb='00076d'><b>#{I18n.t(:to_be_payed, {:scope=>[:receipt]})}:</color>\r\n#{tot_to_be_payed} #{currency_name}</b>",
      "<color rgb='00076d'><b>#{I18n.t(:payed, {:scope=>[:receipt]})}:</color>\r\n#{tot_payed} #{currency_name}</b>"
    ]

    data_table = Ruport::Data::Table.new( :data => data_rows, :column_names => column_names )

    return {
      :data_table => data_table,
      :summary_rows => summary_rows,
      :grouping_total => grand_total
    }
  end
  # ---------------------------------------------------------------------------



################################### WIP down below start #####################à




  # Parses and executes a drag-move operation requested by AJAX call
  #
  def parse_drag_move_operation( from_dom, to_dom, dom_xref_hash )
    logger.debug( "\r\n\r\n---[ #{controller_name()}.parse_drag_move_operation ] ---" ) if DEBUG_VERBOSE
                                                    # --- FROM App.id (dragapp)       |==TO==>  empty date (dropapp):  => Update appointment.date_schedule
    if from_dom =~ /dragapp/ && to_dom =~ /dropapp/
      from_index = dom_xref_hash[ :drag_appointment_doms ].index( from_dom )
      from_id    = dom_xref_hash[ :drag_appointment_ids ][ from_index ]
      to_index   = dom_xref_hash[ :drop_date_schedule_doms ].index( to_dom )
      to_date    = dom_xref_hash[ :drop_date_schedules ][ to_index ]
      appointment = Appointment.find( from_id )

      if appointment                                # (The negation of this should never occur)
        appointment.date_schedule = to_date
        appointment.updated_on = Time.now
        unless appointment.save
          flash[:error] = as_('Save failure.')
          log_error( "ActiveRecord SAVE Failure during parse_drag_move_operation( #{from_dom} |=> #{to_dom} )" )
        end
      else
        flash[:error] = as_('Cannot find the appointment to be moved.')
        log_error( "Cannot find the appointment to be moved! In parse_drag_move_operation( #{from_dom} |=> #{to_dom} )" )
      end

                                                    # --- FROM App.id (dragapp)       |==TO==>  empty slot (dropslot): => Create note + Delete appointment
    elsif from_dom =~ /dragapp/ && to_dom =~ /dropslot/
      from_index  = dom_xref_hash[ :drag_appointment_doms ].index( from_dom )
      from_id     = dom_xref_hash[ :drag_appointment_ids ][ from_index ]
      appointment = Appointment.find( from_id )

      if appointment                                # (The negation of this should never occur)
        curr_date_schedule = appointment.date_schedule
        curr_patient_id    = appointment.patient_id
        appointment.destroy if appointment && !appointment.is_receipt_issued?

        schedule = Schedule.new
        schedule.preset_default_values( :date_schedule => curr_date_schedule, :patient_id => curr_patient_id )
        schedule.updated_on = Time.now
        schedule.must_insert = true

        unless schedule.save
          flash[:error] = as_('Save failure.')
          log_error( "ActiveRecord SAVE Failure during parse_drag_move_operation( #{from_dom} |=> #{to_dom} )" )
        end
      else
        flash[:error] = as_('Cannot find the appointment to be moved.')
        log_error( "Cannot find the appointment to be moved! In parse_drag_move_operation( #{from_dom} |=> #{to_dom} )" )
      end

                                                    # --- FROM Schedule.id (dragslot)  |==TO==>  empty date (dropapp):  => Create appointment with default values + Update note as 'done'
    elsif from_dom =~ /dragslot/ && to_dom =~ /dropapp/
      from_index  = dom_xref_hash[ :drag_schedule_doms ].index( from_dom )
      from_id     = dom_xref_hash[ :drag_schedule_ids ][ from_index ]
      to_index    = dom_xref_hash[ :drop_date_schedule_doms ].index( to_dom )
      to_date     = dom_xref_hash[ :drop_date_schedules ][ to_index ]
      schedule    = Schedule.find( from_id )

      if schedule                                   # (The negation of this should never occur)
        curr_patient_id    = schedule.patient_id
        schedule.is_done   = true

        appointment = Appointment.new
        appointment.preset_default_values( :date_schedule => to_date, :patient_id => curr_patient_id )

        unless appointment.save && schedule.save
          flash[:error] = as_('Save failure.')
          log_error( "ActiveRecord SAVE Failure during parse_drag_move_operation( #{from_dom} |=> #{to_dom} )" )
        end
      else
        flash[:error] = as_('Cannot find the schedule note to be processed.')
        log_error( "Cannot find the schedule note to be processed! In parse_drag_move_operation( #{from_dom} |=> #{to_dom} )" )
      end
    end
                                                    # --- FROM Schedule.id (dragslot)  |==TO==>  empty slot (dropslot): => (Do nothing)
  end
  # ---------------------------------------------------------------------------

end
