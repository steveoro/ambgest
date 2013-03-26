class PatientsController < ApplicationController

  # Require authorization before invoking any of this controller's actions:
  before_filter :authorize


  # Default action
  def index
    ap = AppParameter.get_parameter_row_for( :patients )
    @max_view_height = ap.get_view_height()
  end
  # ---------------------------------------------------------------------------


  # Manage a single patient using +id+ as parameter
  #
  def manage
#    logger.debug( "* Manage Patient ID: #{params[:id]}" )
    @patient_id = params[:id]
    patient = Patient.find_by_id( @patient_id )
    redirect_to( patients_path() ) and return unless patient

    @patient_name = patient.get_full_name
                                                    # Compute the filtering parameters:
    ap = AppParameter.get_parameter_row_for( :patients_manage )
    @max_view_height = ap.get_view_height()
                                                    # Having the parameters, apply the resolution and the radius backwards:
    start_date = DateTime.now.strftime( ap.get_filtering_resolution )
                                                    # Set the (default) parameters for the scope configuration: (actual used value will be stored inside component_session[])
    @filtering_date_start  = ( Date.parse( start_date ) - ap.get_filtering_radius ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
    @filtering_date_end    = ( Date.parse( start_date ) + ap.get_filtering_radius ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
  end
  # ---------------------------------------------------------------------------

end
