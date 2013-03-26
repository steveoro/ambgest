#
# Specialized dual-detail grid component with integrated filtering panel.
#
# - author: Steve A.
# - vers. : 0.35.20130222
#
# == Params
#
# - <tt>:record_id</tt> must be set during component configuration and must point to the current header's Patient.id
# - <tt>:height</tt> must be set during component configuration and must point to the max view height
#
# - <tt>:filtering_date_start</tt> => starting date for the filtering of the data set of each tab
# - <tt>:filtering_date_end</tt> => ending date for the filtering of the data set of each tab
#
# - <tt>:class_tab1</tt>, <tt>:class_tab2</tt> => component classes used to define each tab
# - <tt>:title_tab1</tt>, <tt>:title_tab2</tt> => string titles for each tab
# - <tt>:scope_sql_tab1</tt>, <tt>:scope_sql_tab2</tt> => scope SQL string used by each grid component;
#   assumed to use <tt>:record_id</tt> and both the filtering dates as parameters 1 (record id), 2 (date start) and 3 (date end).
# - <tt>:strong_default_attrs</tt> => default attr hash passed to the grid components
#
class FilteredTabbedDualPanel < Netzke::Basepack::BorderLayoutPanel

  js_properties(
    :prevent_header => true,
    :header => false,
    :border => true
  )


  def configuration
    super.merge(
      :persistence => true,
      :min_width => 900,
      :items => [
        :filtering_header.component( :region => :north ),
        :dual_tabbed_view.component( :region => :center )
      ]
    )
  end
  # ---------------------------------------------------------------------------


  js_method :init_component, <<-JS
    function() {
      #{js_full_class_name}.superclass.initComponent.call( this );
    }  
  JS
  # ---------------------------------------------------------------------------
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
  end
  # ---------------------------------------------------------------------------


  component :dual_tabbed_view do
    {
      :class_name => "Netzke::Basepack::TabPanel",
      :width => "98%",
      :border => true,
      :view_config => {
        :force_fit => true # force the columns to occupy all the available width
      },
      :prevent_header => true,
      :active_tab => 0,

      :items => [
        {
          :class_name => config[:class_tab1],
          :title      => config[:title_tab1],
          :scope      => [
            config[:scope_sql_tab1],
            config[:record_id],
            component_session[:filtering_date_start] ||= config[:filtering_date_start],
            component_session[:filtering_date_end] ||= config[:filtering_date_end]
          ],
          :strong_default_attrs => config[:strong_default_attrs],
                                                    # Dynamic height resizing:
          :height => config[:height] - FilteringDateRangePanel::FILTERING_PANEL_DEFAULT_HEIGHT
        },
        {
          :class_name => config[:class_tab2],
          :title      => config[:title_tab2],
          :scope      => [
            config[:scope_sql_tab2],
            config[:record_id],
            component_session[:filtering_date_start] ||= config[:filtering_date_start],
            component_session[:filtering_date_end] ||= config[:filtering_date_end]
          ],
          :strong_default_attrs => config[:strong_default_attrs],
                                                    # Dynamic height resizing:
          :height => config[:height] - FilteringDateRangePanel::FILTERING_PANEL_DEFAULT_HEIGHT,
          :lazy_loading => true
        }
      ]
    }
  end
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
end
