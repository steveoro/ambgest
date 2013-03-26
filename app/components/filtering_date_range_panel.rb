#
# == Custom Filtering Panel component implementation
#
# - author: Steve A.
# - vers. : 0.35.20130222 (AmbGest3 version: with no Firm support but with multiple embedding support on TabPanels)
#
# A simple panel that allows to set a date range with two date pickers.
# The date pickers will take their initial values from configuration which, in turn,
# may come from the <tt>component_session</tt> of the parent Netzke component.
#
# Assumes the filtering will be applied to another Netzke component either named <tt>'list_view_grid'</tt>
# (in case of a single grid) or  <tt>'dual_tabbed_view'</tt> (in case of a dual grid -- see the constants below).
#
# Assumes the container (parent) Netzke component will have an endpoint defined,
# called <tt>'update_filtering_scope'</tt>, which it should just update the parent component session
# to store the current filtering parameter values (passed via JS call from the date-pickers).
#
# The filtering fields (as well as their component IDs) that define the filtering range
# parameters are named: (self-explanatory, with unique ID and symbol equal to their name)
#
# - <tt>filtering_date_start</tt>, a.k.a. <tt>FilteringDateRangePanel::FILTERING_DATE_START_CMP_ID</tt>
# - <tt>filtering_date_end</tt>, a.k.a. <tt>FilteringDateRangePanel::FILTERING_DATE_END_CMP_ID</tt>
#
class FilteringDateRangePanel < Netzke::Basepack::Panel

  # Name of the Netzke component that is assumed to contain the data grid that will use the
  # session-stored filtering parameters.
  # (FilteringDateRangePanel can use only one filtering destination, but will detect which one is defined)
  #
  NETZKE_CMP_TO_BE_FILTERED_NAME        = 'list_view_grid'

  # Name of the Netzke tabbed dual-view component that is assumed to contain the couple of data grids
  # that will use the session-stored filtering parameters.
  # (FilteringDateRangePanel can use only one filtering destination, but will detect which one is defined)
  #
  NETZKE_TABBED_CMP_TO_BE_FILTERED_NAME = 'dual_tabbed_view'

  # Component Symbol used to uniquely address the date-start field of the range
  FILTERING_DATE_START_CMP_SYM  = :filtering_date_start

  # Component ID used to uniquely address the date-start field of the range
  FILTERING_DATE_START_CMP_ID   = FILTERING_DATE_START_CMP_SYM.to_s

  # Component Symbol used to uniquely address the date-end field of the range
  FILTERING_DATE_END_CMP_SYM    = :filtering_date_end

  # Component ID used to uniquely address the date-end field of the range
  FILTERING_DATE_END_CMP_ID     = FILTERING_DATE_END_CMP_SYM.to_s

  FILTERING_PANEL_DEFAULT_HEIGHT = 35


  js_properties(
    :prevent_header => true
  )


  def configuration
    super.merge(
      :frame => true,
      :min_width => 500,
      :min_height => FILTERING_PANEL_DEFAULT_HEIGHT,
      :height => FILTERING_PANEL_DEFAULT_HEIGHT,
      :margin => '1 1 1 1',
      :fieldDefaults => {
        :msgTarget => 'side',
        :autoFitErrors => false
      },
      :layout => 'hbox',
      :items => [
        {
          :fieldLabel => I18n.t(:data_filtered_from, :scope => [:agex_action]),
          :labelWidth => 130,
          :margin => '1 6 0 0',
          :id   => FILTERING_DATE_START_CMP_ID,
          :name => FILTERING_DATE_START_CMP_ID,
          :xtype => 'datefield',
          :vtype => 'daterange',
          :endDateField => FILTERING_DATE_END_CMP_ID,
          :width => 230,
          :enable_key_events => true,
          :format => AGEX_FILTER_DATE_FORMAT_EXTJS,
          :value => super[FILTERING_DATE_START_CMP_SYM]
        },
        {
          :fieldLabel => I18n.t(:data_filtered_to, :scope => [:agex_action]),
          :labelWidth => 20,
          :margin => '1 2 0 6',
          :id   => FILTERING_DATE_END_CMP_ID,
          :name => FILTERING_DATE_END_CMP_ID,
          :xtype => 'datefield',
          :vtype => 'daterange',
          :startDateField => FILTERING_DATE_START_CMP_ID,
          :width => 120,
          :enable_key_events => true,
          :format => AGEX_FILTER_DATE_FORMAT_EXTJS,
          :value => super[FILTERING_DATE_END_CMP_SYM]
        }
      ]
    )
  end
  # ---------------------------------------------------------------------------


  js_method :init_component, <<-JS
    function(){
      #{js_full_class_name}.superclass.initComponent.call(this);
                                                    // Add the additional 'advanced' VTypes used for validation:
      Ext.apply( Ext.form.field.VTypes, {
          daterange: function( val, field ) {
              var date = field.parseDate( val );
              if ( !date ) {
                  return false;
              }
                                  // 'startDateField' property will be defined only on END date
              if ( field.startDateField && (!this.dateRangeMax || (date.getTime() != this.dateRangeMax.getTime())) ) {
                  var startDt = Ext.ComponentManager.get( field.startDateField );
                  this.dateRangeMax = date;
                  startDt.setMaxValue( date );
                  startDt.validate();
              }
                                  // 'endDateField' property will be defined only on START date
              else if ( field.endDateField && (!this.dateRangeMin || (date.getTime() != this.dateRangeMin.getTime())) ) {
                  var endDt = Ext.ComponentManager.get( field.endDateField );
                  this.dateRangeMin = date;
                  endDt.setMinValue( date );
                  endDt.validate();
              }
              /* Always return true since we're only using this vtype to set the
               * min/max allowed values (these are tested for after the vtype test)
               */
              return true;
          }
      });

      this.addEventListenersFor( "#{FILTERING_DATE_START_CMP_ID}" );
      this.addEventListenersFor( "#{FILTERING_DATE_END_CMP_ID}" );
    }  
  JS
  # ---------------------------------------------------------------------------


  # Adds the required event listeners for the specified dateField widget
  #
  js_method :add_event_listeners_for, <<-JS
    function( dateCtlName ) {                       // Retrieve the filtering date field sub-Component:
      var fltrDate = this.getComponent( dateCtlName );
  
      fltrDate.on(                                  // Add listener on value select:
        'select',
        function( field, value, eOpts ) {
          var sDate = Ext.Date.format(field.getValue(), "#{AGEX_FILTER_DATE_FORMAT_EXTJS}");
          var opt = new Object;
          opt[ dateCtlName.valueOf() ] = sDate;
                                                    // Call the endpoint defined inside the parent component:
          var parentCmp = this.getParentNetzkeComponent();
// DEBUG
//          console.log( parentCmp );
          parentCmp.updateFilteringScope( opt );
                                                    // Update the grid(s) component data:
          var cmp = parentCmp.getComponent("#{NETZKE_CMP_TO_BE_FILTERED_NAME}");
          if ( cmp != null ) {                      // Detect which destination must be updated:
            cmp.getStore().load();
          }
          else {                                    // If it is the dual-grid, update both items (grids)
            cmp = parentCmp.getChildNetzkeComponent("#{NETZKE_TABBED_CMP_TO_BE_FILTERED_NAME}");
// DEBUG
//            console.log( cmp );
            cmp.getActiveTab().items.first().getStore().load();
          }
        },
        this
      );

      fltrDate.on(                                  // Add listener on ENTER keypress:
        'keypress',
        function( field, eventObj, eOpts ) {
          if ( eventObj.getKey() == Ext.EventObject.ENTER ) {
            try {
              var sDate = Ext.Date.format(field.getValue(), "#{AGEX_FILTER_DATE_FORMAT_EXTJS}");
                                                    // The following will be executed only if sDate is valid:
              var opt = new Object;
              opt[ dateCtlName.valueOf() ] = sDate;
                                                    // Call the endpoint defined inside the parent component:
              var parentCmp = this.getParentNetzkeComponent();
// DEBUG
//              console.log( parentCmp );
              parentCmp.updateFilteringScope( opt );
                                                    // Update the grid(s) component data:
              var cmp = parentCmp.getComponent("#{NETZKE_CMP_TO_BE_FILTERED_NAME}");
              if ( cmp != null ) {                  // Detect which destination must be updated:
                cmp.getStore().load();
              }
              else {                                  // If it is the dual-grid, update both items (grids)
                cmp = parentCmp.getChildNetzkeComponent("#{NETZKE_TABBED_CMP_TO_BE_FILTERED_NAME}");
// DEBUG
//                console.log( cmp );
                cmp.getActiveTab().items.first().getStore().load();
              }
            }
            catch(e) {
            }
          }
        },
        this
      );
    }
  JS
  # ---------------------------------------------------------------------------
end
