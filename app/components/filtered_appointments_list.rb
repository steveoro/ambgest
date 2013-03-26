#
# Appointment rows list/grid component implementation with date filtering support
#
# - author: Steve A.
# - vers. : 0.35.20130221
#
class FilteredAppointmentsList < Netzke::Basepack::BorderLayoutPanel

  js_properties(
    :prevent_header => true,
    :header => false,
    :border => true
  )


  def configuration
    super.merge(
      :persistence => true,
      :items => [
        :filtering_header.component( :region => :north ),
        :list_view_grid.component( :region => :center )
      ]
    )
  end
  # ---------------------------------------------------------------------------


  component :filtering_header do
    {
      :class_name => "FilteringDateRangePanel",
      :filtering_date_start => component_session[:filtering_date_start] ||= config[:filtering_date_start],
      :filtering_date_end   => component_session[:filtering_date_end] ||= config[:filtering_date_end]
    }
  end
  # ---------------------------------------------------------------------------


  # Endpoint for refreshing the "global" data scope of the grid on the server-side component
  # (simply by updating the component session field used as variable parameter).
  #
  # == Params (either are facultative)
  # - filtering_date_start : an ISO-formatted (Y-m-d) date with which the grid scope can be updated
  # - filtering_date_end : as above, but for the ending-date of the range
  #
  endpoint :update_filtering_scope do |params|
#    logger.debug( "\r\n--- update_filtering_scope: #{params.inspect}" )

    # [Steve, 20120221] Since the component_session returns a member of the component and not
    # a constant value, is treated by the config hash as a reference, thus it suffices to update
    # its value to see it also updated inside the component config structure itself.
    component_session[:filtering_date_start] = params[:filtering_date_start] if params[:filtering_date_start]
    component_session[:filtering_date_end]   = params[:filtering_date_end] if params[:filtering_date_end]

    # [Steve, 20120221 - DONE] The following can be replaced (totally, with no return hash) by a
    # single JS call:
    #
    #           this.getComponent('filtering_header').getStore().load();
    #
    # ...placed just after each this.updateFilteringScope(...) call inside the event listeners.
    #
    # Keep in mind that invoking the loadStoreData() server-side won't trigger the loading mask
    # automatically on the UI (instead the above JS command does everything in one).
    #
    # But for sake of clarity and to illustrate how to do it server-side, here it is anyway:
    #
#                                                    # Rebuild server-side the data of the grid
#    cmp_grid = component_instance( :list_view_grid )
#    cmp_data = cmp_grid.get_data
#                                                    # The following will the invoke Ext.data.Store.loadData on the client-side:
#    {
#      :list_view_grid => { :load_store_data => cmp_data }
#    }
  end
  # ---------------------------------------------------------------------------


  component :list_view_grid do
    {
      :class_name => "AppointmentsGrid",
      # [20130213] DO NOT use lambda here as it enforces the default sorting as FIXED: it alters
      # the scope order itself and it disables the on-click column ordering.
      :scope => ( config[:patient_id] ?
          [
            "patient_id = ? AND ( (DATE_FORMAT(date_schedule,'#{AGEX_FILTER_DATE_FORMAT_SQL}') >= ? AND DATE_FORMAT(date_schedule,'#{AGEX_FILTER_DATE_FORMAT_SQL}') <= ?) OR date_schedule IS NULL )",
            config[:patient_id],
            component_session[:filtering_date_start] ||= config[:filtering_date_start],
            component_session[:filtering_date_end] ||= config[:filtering_date_end]
          ] :
          [
            "DATE_FORMAT(date_schedule,'#{AGEX_FILTER_DATE_FORMAT_SQL}') >= ? AND (DATE_FORMAT(date_schedule,'#{AGEX_FILTER_DATE_FORMAT_SQL}') <= ? OR date_schedule IS NULL)",
            component_session[:filtering_date_start] ||= config[:filtering_date_start],
            component_session[:filtering_date_end] ||= config[:filtering_date_end]
          ]
      )
    }
  end
  # ---------------------------------------------------------------------------
end
