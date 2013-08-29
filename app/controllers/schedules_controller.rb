class SchedulesController < ApplicationController

  # Require authorization before invoking any of this controller's actions:
  before_filter :authorize


  # Default action.
  #
  # == Params:
  #
  # - <tt>:date_schedule</tt>
  #   When set, it will override the current date inside the week to be displayed.
  #
  def index
# DEBUG
#    logger.debug( "\r\n\r\n---[ #{controller_name()}.index ] ---" )
#    logger.debug( "Params: #{params.inspect()}" )
    ap = AppParameter.get_parameter_row_for( :schedules )
    @max_view_height = ap.get_view_height()

    if ( params[:date_schedule].blank? || params[:date_schedule].nil? )
                                                    # Having the parameters, apply the resolution and the radius backwards:
      start_date = DateTime.now.strftime( ap.get_filtering_resolution )
                                                    # Set the (default) parameters for the scope configuration: (actual used value will be stored inside component_session[])
      @filtering_date_start  = ( Date.parse( start_date ) - ap.get_filtering_radius ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
      @filtering_date_end    = ( Date.parse( start_date ) + ap.get_filtering_radius ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
      @override_filtering    = nil
    else
      begin
        curr_date = Date.parse params[:date_schedule]
      rescue
        logger.warn("**[W]** - #{controller_name()}.index(): Warning: invalid date specified as paramaters! (params=#{params.inspect})")
        curr_date = Date.today
      end
                                                    # Compute actual date range for the SQL data extraction query:
      @filtering_date_start = Schedule.get_week_start( curr_date ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
      @filtering_date_end = Schedule.get_week_end( curr_date ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
      # [20130212] We must use the AGEX_FILTER_DATE_FORMAT_SQL for the filtering dates used by
      # the custom Netzke component for the date filtering, because the result text from the
      # method Schedule.get_week_start/end_for_mysql_param() uses a DateTime instance instead of a simple Date
      # (used inside the FilteringDateRangePanel)
      @override_filtering    = true
    end

# DEBUG
#    logger.debug( "@filtering_date_start: #{@filtering_date_start.inspect()}" )
#    logger.debug( "@filtering_date_end:   #{@filtering_date_end.inspect()}" )
    @context_title = I18n.t(:schedules_list, {:scope=>[:schedule]})
  end
  # ---------------------------------------------------------------------------

end
