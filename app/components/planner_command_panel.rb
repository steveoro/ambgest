#
# == Custom Week-planner component implementation
#
# - author: Steve A.
# - vers. : 3.03.03.20130326
#
# A custom panel that acts as a full-fledged week planner.
#
class PlannerCommandPanel < Netzke::Basepack::Panel 

  # Component Symbol used to uniquely address the date-start field of the range
  FILTERING_DATE_CMP_SYM    = :filtering_date

  FAST_BACKWD_BTN_CMP_SYM   = :week_fast_backward
  BACKWARD_BTN_CMP_SYM      = :week_backward
  CURRENT_BTN_CMP_SYM       = :week_current
  FORWARD_BTN_CMP_SYM       = :week_forward
  FAST_FWD_BTN_CMP_SYM      = :week_fast_forward

  SCHEDULE_ADD_BTN_CMP_SYM  = :schedule_note_add
  SCHEDULE_VIEW_BTN_CMP_SYM = :schedule_notes_current
  INCOME_ANALYSIS_BTN_CMP_SYM = :income_analysis


  # Component ID used to uniquely address the date-start field of the range
  FILTERING_DATE_CMP_ID   = FILTERING_DATE_CMP_SYM.to_s


  js_properties(
    :prevent_header => true,
    :header => false
  )


  def configuration
    super.merge(
      :frame => true,
      :min_width => 500,
      :min_height => 35,
      :height => 35,
      :margin => '1 1 1 1',
      :fieldDefaults => {
        :msgTarget => 'side',
        :autoFitErrors => false
      },
      :layout => 'hbox',
      :items => [
        create_button_config( FAST_BACKWD_BTN_CMP_SYM, :week_plan, 'resultset_fastbkwd.png' ),
        create_button_config( BACKWARD_BTN_CMP_SYM, :week_plan, 'resultset_previous.png' ),
        {
          :fieldLabel => I18n.t(:go_to_date, :scope => [:agex_action]),
          :labelWidth => 80,
          :margin => '1 5 0 5',
          :id   => FILTERING_DATE_CMP_ID,
          :name => FILTERING_DATE_CMP_ID,
          :xtype => 'datefield',
          :vtype => 'daterange',
          :width => 180,
          :enable_key_events => true,
          :format => AGEX_FILTER_DATE_FORMAT_EXTJS,
          :value => super[ FILTERING_DATE_CMP_SYM ]
        },
        create_button_config( CURRENT_BTN_CMP_SYM, :week_plan, 'calendar_view_week.png' ),
        create_button_config( FORWARD_BTN_CMP_SYM, :week_plan, 'resultset_next.png' ),
        create_button_config( FAST_FWD_BTN_CMP_SYM, :week_plan, 'resultset_fastfwd.png' ),
        {
          :xtype => 'container',
          :width => 30
        },
        create_button_config( SCHEDULE_ADD_BTN_CMP_SYM, :week_plan, 'calendar_add.png' ),
        create_button_config( SCHEDULE_VIEW_BTN_CMP_SYM, :week_plan, 'calendar_edit.png' ),
        create_button_config( INCOME_ANALYSIS_BTN_CMP_SYM, :week_plan, 'money.png' )
      ]
    )
  end
  # ---------------------------------------------------------------------------


  # Generates a Ruby Hash containing a configuration compatible with ExtJS Button-widget definition,
  # to be used inside an items list of a panel container.
  #
  # Works similarly to ApplicationHelper::create_extjs_button_config, but instead of returning a parsable
  # Javascript string, the result is a plain Ruby Hash.
  #
  # == Params:
  #
  # <tt>action_title_i19n_sym</tt> => Symbol for the I18n title for the button. The method assumes also that
  #                                   a tooltip symbol is defined with a "_tooltip" appended on the title symbol
  # <tt>action_title_i19n_scope_sym</tt> => Symbol for the I18n scope of the localization;
  #                                         it can be nil for using the default global scope
  # <tt>image_name</tt> => file name for the image to be used in the button, searched under "/images/icons"
  #
  def create_button_config( action_title_i19n_sym, action_title_i19n_scope_sym, image_name = "cog.png" )
    action_text  = I18n.t( action_title_i19n_sym.to_sym, {:scope => [action_title_i19n_scope_sym ? action_title_i19n_scope_sym.to_sym : nil]} )
    tooltip_text = I18n.t( "#{action_title_i19n_sym}_tooltip".to_sym, {:scope => [action_title_i19n_scope_sym ? action_title_i19n_scope_sym.to_sym : nil]} )
    {
      :xtype => 'button',
      :id    => action_title_i19n_sym.to_s,
      :name  => action_title_i19n_sym.to_s,
      :icon  => "/images/icons/#{ image_name }",
      :text  => "#{ action_text }",
      :tooltip  => "#{ tooltip_text }",
      :margin  => '0 3 3 3'
    }
  end
  # ---------------------------------------------------------------------------


  # Internal component used only as pop-up forms for editing/creating schedule notes contents.
  #
  # To check out the config. of the add_form / edit_form component (WeekPlannerSlotDetails)
  # which is used for each individual week planner cell, see WeekPlannerPanel.
  #
  component :add_schedule_form do
    form_config = {
      :class_name => "ScheduleDetails",
      :record => Schedule.new()
    }

    {
      :lazy_loading => true,
      :class_name => "Netzke::Basepack::GridPanel::RecordFormWindow",
      :title => "#{I18n.t(:add_schedule, {:scope=>[:schedule]})}",
      :min_width => 490,
      :button_align => "right",
      :items => [ form_config ]
    }
  end
  # ---------------------------------------------------------------------------


  js_method :init_component, <<-JS
    function() {
      #{js_full_class_name}.superclass.initComponent.call(this);
                                                    // Add the additional 'advanced' VTypes used for validation:
      Ext.apply( Ext.form.field.VTypes, {
          daterange: function( val, field ) {
              var date = field.parseDate( val );
              if ( !date ) {
                  return false;
              }
              /* Always return true since we're only using this vtype to set the
               * range values for the current week
               */
              return true;
          }
      });

      this.addEventListenersFor( "#{ FILTERING_DATE_CMP_ID }" );
                                                    // Set the button handlers
      this.addClickListenerFor( "#{ FAST_BACKWD_BTN_CMP_SYM }", -14 );
      this.addClickListenerFor( "#{ BACKWARD_BTN_CMP_SYM }", -7 );
      this.addClickListenerFor( "#{ CURRENT_BTN_CMP_SYM }", 0 );
      this.addClickListenerFor( "#{ FORWARD_BTN_CMP_SYM }", 7 );
      this.addClickListenerFor( "#{ FAST_FWD_BTN_CMP_SYM }", 14 );

      this.addClickListenerForAddSchedule();

      this.addClickListenerForInvokingCtrlMethod(
        "#{ SCHEDULE_VIEW_BTN_CMP_SYM }",
        "#{ Netzke::Core.controller.schedules_path() }"
      );
      this.addClickListenerForInvokingCtrlMethod(
        "#{ INCOME_ANALYSIS_BTN_CMP_SYM }",
        "#{ Netzke::Core.controller.income_analysis_path() }"
      );
    }  
  JS
  # ---------------------------------------------------------------------------


  # Adds the required event listeners for the specified dateField widget
  #
  js_method :add_event_listeners_for, <<-JS
    function( dateCtlName ) {                       // Retrieve the filtering date field sub-Component:
      var fltrDate = Ext.ComponentMgr.get( dateCtlName );

      fltrDate.on(                                  // Add listener on value select:
        'select',
        function( field, value, eOpts ) {
          var sDate = Ext.Date.format(field.getValue(), "#{AGEX_FILTER_DATE_FORMAT_EXTJS}");
          var opt = new Object;
          opt[ dateCtlName.valueOf() ] = sDate;
                                                    // Call the endpoint defined inside the parent component:
          this.getParentNetzkeComponent().updateFilteringScope( opt );
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
              this.getParentNetzkeComponent().updateFilteringScope( opt );
            }
            catch(e) {
            }
          }
        },
        this
      );
    }
  JS


  # Adds the required click-event listeners for the specified button id
  #
  # == Params:
  #
  # iDirectionInDays: number of days that have to be added to the currently filtering date
  #                   to get the new destination date searched upon button click.
  #                   If == 0, the filtering date will be reset to the current date.
  #
  js_method :add_click_listener_for, <<-JS
    function( btnCmpName, iDirectionInDays ) {      // Retrieve the button component:
      var btn = Ext.ComponentMgr.get( btnCmpName );
      btn.on(
        'click',
        function( button ) {
          var fltrDate = Ext.ComponentMgr.get( "#{ FILTERING_DATE_CMP_ID }" );
// DEBUG
//          console.log( 'fltrDate:' );
//          console.log( fltrDate );
          var dtCurrDate = (fltrDate.getValue() != '') && (iDirectionInDays != 0) ? fltrDate.getValue() : new Date();
// DEBUG
//          console.log( 'dtCurrDate:' );
//          console.log( dtCurrDate );
          if ( iDirectionInDays != 0 ) {
            dtCurrDate = Ext.Date.add( dtCurrDate, Ext.Date.DAY, iDirectionInDays );
          }
          fltrDate.setValue( dtCurrDate );          // Update the filtering date
                                                    // Prepare the parameter for the endpoint:
          var opt = new Object;
          opt[ "#{ FILTERING_DATE_CMP_ID }" ] = Ext.Date.format(dtCurrDate, "#{AGEX_FILTER_DATE_FORMAT_EXTJS}");
          this.getParentNetzkeComponent().updateFilteringScope( opt );
        },
        this
      );
    }
  JS


  # "Add schedule note" button handler setter, called from PlannerGrid.
  # Presets the current date_schedule into the form before displaying itself.
  #
  js_method :add_click_listener_for_add_schedule, <<-JS
    function() {
      var btn = Ext.ComponentMgr.get( "#{ SCHEDULE_ADD_BTN_CMP_SYM }" );
      btn.on(
        'click',
        function( button ) {
          var fltrDate = Ext.ComponentMgr.get( "#{ FILTERING_DATE_CMP_ID }" );
          var dtSchedule = (fltrDate.getValue() != '') ? fltrDate.getValue() : new Date();
                                                    // *** CREATE Form ***
          this.loadNetzkeComponent( {
            name: "add_schedule_form",
            callback: function(win) {
              var cmp = win.getChildNetzkeComponent('netzke_0');
              var frm = cmp.getForm();
              frm.setValues( {'date_schedule': dtSchedule} );
              var f = frm.findField('date_schedule');
              f.setReadonlyMode(true);
              win.show();
  
              win.on( 'close', function() {
                if ( win.closeRes === "ok" ) {      // Refresh the planner week, since we may have filled another slot
                  this.getParentNetzkeComponent().updateFilteringScope('');    // This will either use Date.today or the one stored into the component session
                }
              }, this);
              
            },
            scope: this
          } );
        },
        this
      );
    }  
  JS


  # Adds a simple click-event listener for the specified button id, capable of invoking
  # a remote controller action.
  #
  # The parameter sent to the remote controllerPath is 'date_schedule', taken from the
  # currently selected value for FILTERING_DATE_CMP_ID; when null the current date is used.
  #
  js_method :add_click_listener_for_invoking_ctrl_method, <<-JS
    function( btnCmpName, controllerPath  ) {       // Retrieve the button component:
      var btn = Ext.ComponentMgr.get( btnCmpName );
      btn.on(
        'click',
        function( button ) {
          var fltrDate = Ext.ComponentMgr.get( "#{ FILTERING_DATE_CMP_ID }" );
          var dtCurrDate = (fltrDate.getValue() != '') ? fltrDate.getValue() : new Date();
          this.setDisabled( true );                 // Block the controls until the server responds
                                                    // Redirect to this URL: (which performs a send_data rails command)
          location.href = controllerPath + "?date_schedule=" +
                          Ext.Date.format(dtCurrDate, "#{AGEX_FILTER_DATE_FORMAT_EXTJS}");
        },
        this
      );
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
end
