#
# == Custom Week-planner component implementation
#
# - author: Steve A.
# - vers. : 3.03.03.20130326
#
# A custom panel that acts as a full-fledged week planner.
#
class PlannerGrid < Netzke::Basepack::Panel 

  js_properties(
    :prevent_header => true,
    :header => false
  )

  js_property :cell_config_array
  js_property :cmp_planner_grid

  js_property :i_appointment_length
  js_property :i_am_start_hour
  js_property :i_am_start_min
  js_property :i_am_tot_appointments
  js_property :i_pm_start_hour
  js_property :i_pm_start_min
  js_property :i_pm_tot_appointments
                                                    # FIXME Note: Netzke sets Sunday as #0, but is the 7th day in locale En/It
  js_property :sa_abbr_day_names
  js_property :sa_abbr_month_names

  js_property :css_bgnd_empty_slot_normal
  js_property :css_bgnd_empty_slot_mouseover
  js_property :css_bgnd_empty_slot_today_normal
  js_property :css_bgnd_empty_slot_today_mouseover
  js_property :css_bgnd_used_slot_normal
  js_property :css_bgnd_used_slot_mouseover
  js_property :css_bgnd_used_slot_today_normal
  js_property :css_bgnd_used_slot_today_mouseover
  # ---------------------------------------------------------------------------


  def configuration
    super.merge(
      :frame => true,
      :margin => '1 1 1 1',
      :layout => {
        :type => 'vbox',
        :align => 'stretch'
      },
      :items => []
    )
  end
  # ---------------------------------------------------------------------------


  # Working Synopsis:
  #
  # 1) obtain component name for items[] above  => cmpPlannerGrid = Ext.ComponentMgr.get('weekly_planner_panel__planner_grid')
  # 2) use JS method / initComponent to retrieve JSON array of appointments via endpoint
  #   2.1) create unmutable grid by way of an array of sub-panel configs based on data obtained in :after_retrieve_planner_config_hash
  #   2.2) create a valid JS method as onClick handler for each panel cell (cfr. takes_with_tags_panel in BandRecs)
  #   2.3) create special (Sunday) Schedule notes cells
  #
  # 3) convert all create_planner_config_xxx method to JS to scan'n'update each item/cell config
  #   3.1) for each existing item in items[], set appointment values || clear items if not existing or set
  #
  # 4) create Form window for Add/Edit new appointment w/custom buttons
  #   4.1) custom button: issue receipt
  #   4.2) custom button: print receipt (visible when receipt issued)
  #

  js_method :init_component, <<-JS
    function() {
      #{ js_full_class_name }.superclass.initComponent.call(this);
                                                    // Init the constant arrays of weekday/month names
      saAbbrDayNames = [
          "#{I18n.t( :abbr_day_names, :scope => [:date] )[1]}",
          "#{I18n.t( :abbr_day_names, :scope => [:date] )[2]}",
          "#{I18n.t( :abbr_day_names, :scope => [:date] )[3]}",
          "#{I18n.t( :abbr_day_names, :scope => [:date] )[4]}",
          "#{I18n.t( :abbr_day_names, :scope => [:date] )[5]}",
          "#{I18n.t( :abbr_day_names, :scope => [:date] )[6]}",
          "#{I18n.t( :abbr_day_names, :scope => [:date] )[0]}"
      ];
      saAbbrMonthNames = [
          "-",                                      // (no 0-th month!)
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[1]}",
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[2]}",
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[3]}",
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[4]}",
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[5]}",
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[6]}",
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[7]}",
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[8]}",
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[9]}",
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[10]}",
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[11]}",
          "#{I18n.t( :abbr_month_names, :scope => [:date] )[12]}"
      ];
      cssBgndEmptySlotNormal          = "#c0f8c0";
      cssBgndEmptySlotMouseover       = "#87F887";
      cssBgndEmptySlotTodayNormal     = "#f8ff80";
      cssBgndEmptySlotTodayMouseover  = "#F4FF30";
      cssBgndUsedSlotNormal           = "#b0e8b0";
      cssBgndUsedSlotMouseover        = "#80e8b0";
      cssBgndUsedSlotTodayNormal      = "#e8ef70";
      cssBgndUsedSlotTodayMouseover   = "#d8ef70";
                                                    // Call endpoint to dynamically build-up a button for each defined tag
      this.retrievePlannerConfigHash( '' );
    }
  JS
  # ---------------------------------------------------------------------------


  # Retrieves the immutable PlannerGrid configuration that will be used to build up
  # the grid/table component items list. (That will be filled later on with the actual
  # data coming from the current filtering date range.)
  #
  endpoint :retrieve_planner_config_hash do |params|
# DEBUG
#    logger.debug( "\r\n\r\n*** PlannerGrid.retrieve_planner_config_hash( params=<#{params.inspect}> ) endpoint called.\r\n" )
    week_start = Schedule.get_week_start( Date.today )
    appointment_length = AppParameterCustomizations.get_appointment_length_in_mins()
                                        # Morning (AM) schedule:
    am_schedule_hash = AppParameterCustomizations.get_morning_schedule()
    throw( "Missing AppParameter configuration parameter values for default AM schedule size! Check database app_parameter table." ) if am_schedule_hash[:start_time].nil? || am_schedule_hash[:total_appointments].nil?
# DEBUG
#    puts "\r\n\r\n========================================== AM\r\n- app_length: #{appointment_length}"
#    puts "- AM start_time: #{am_schedule_hash[:start_time]}, AM total_appointments: #{am_schedule_hash[:total_appointments]}"
                                        # Noon (PM) schedule:
    pm_schedule_hash = AppParameterCustomizations.get_noon_schedule()
    throw( "Missing AppParameter configuration parameter values for default PM schedule size! Check database app_parameter table." ) if pm_schedule_hash[:start_time].nil? || pm_schedule_hash[:total_appointments].nil?
# DEBUG
#    puts "\r\n\r\n========================================== PM"
#    puts "- PM start_time #{pm_schedule_hash[:start_time]}, PM total_appointments #{pm_schedule_hash[:total_appointments]}"
    { 
      :after_retrieve_planner_config_hash => {
        :week_start => week_start,
        :appointment_length => appointment_length,
        :am_schedule => am_schedule_hash,
        :pm_schedule => pm_schedule_hash
      }
    }
  end
  # ---------------------------------------------------------------------------


  # Builds-up the empty Planner component after receiving the base configuration for
  # each slot cell (size and number).
  #
  # The component will be filled-in with actual data only afterwards by the update method of
  # the filtering widgets.
  #
  js_method :after_retrieve_planner_config_hash, <<-JS
    function( resultObj ) {
      if ( ! Ext.isEmpty(resultObj) ) {             // Any results to process?
        var sWeekStart = resultObj.weekStart;                       // '2012-12-03'
                                                    // Global JS properties: (scope: component)
        iAppointmentLength  = resultObj.appointmentLength;           // 30
        iAmStartHour        = resultObj.amSchedule.startHour;        // 8
        iAmStartMin         = resultObj.amSchedule.startMin;         // 30
        iAmTotAppointments  = resultObj.amSchedule.totalAppointments;// 7
        iPmStartHour        = resultObj.pmSchedule.startHour;        // 13
        iPmStartMin         = resultObj.pmSchedule.startMin;         // 30
        iPmTotAppointments  = resultObj.pmSchedule.totalAppointments;// 14

        var dtToday = new Date();
        var dtNewWeekStart = Ext.Date.parse( sWeekStart, "Y-m-d" );
        var sTodayID = Ext.Date.format(dtToday, "Ymd");
                                                    // Build-up component array config:
        cellConfigArray = new Array();
                                                    // Pre-compute an optimized cell width:
        cmpPlannerGrid = Ext.ComponentMgr.get('weekly_planner_panel__planner_grid');
        var iFullWidth = cmpPlannerGrid.getWidth() - 8;  // Spare 1 pixels for each cell-column border (6) + 1 for each side
        var iCellWidth = (iFullWidth - (iFullWidth % 7)) / 7;
        var iHeaderHeight = 38;
        var iCellHeight   = 75;

                                                    // == BUILD-UP HEADER function definition == (Uses inline code because component is not yet initialized)

        var fBuildUpHeader = function( dtWeekStart, iColumnWidth, configArray ) {
          var headerConfigArray = new Array();
          var iWkDay = 0;
          var sHeaderBodyStyle = "background-color: #555555; color: #ffffff;" +
                                 "padding-left: 2em; padding-right: 2em; padding-top: 0.5em; padding-bottom: 1em;" +
                                 "font: bold 11px arial,sans-serif; text-align: center; width: 14%; height: 3em;";
          for ( iWkDay=0; iWkDay < 6; iWkDay++ ) {
            var dtCurrDate  = iWkDay > 0 ? Ext.Date.add( dtWeekStart, Ext.Date.DAY, iWkDay ) : dtWeekStart;
            var sCurrCellDay= saAbbrDayNames[ iWkDay ];
            var sCurrCellMonth = saAbbrMonthNames[ Ext.Date.format(dtCurrDate, "n") ];
            var sHeaderText = Ext.Date.format(dtCurrDate, "d ") + sCurrCellMonth + "<br/>" + sCurrCellDay;
                                                      // Add current column header:
            headerConfigArray.push(
                {
                  id: "hdr" + iWkDay,
                  html: sHeaderText,
                  width: iColumnWidth,
                  border: false,
                  height: iHeaderHeight,
                  bodyStyle: sHeaderBodyStyle,
                }
            );
          }
                                                      // Add the special "schedule notes" cell as a the last column:
          headerConfigArray.push({
                id: "hdr6",
                html: "#{ I18n.t(:notes) }",
                width: iColumnWidth,
                border: false,
                height: iHeaderHeight,
                bodyStyle: sHeaderBodyStyle
          });
                                                      // Add the whole header row as a single container item:
          configArray.push({
            layout: {
              type:  'hbox'
            },
            items: headerConfigArray
          });
        }
                                                    // == BUILD-UP ROWS function definition ==

        var fBuildUpRows = function( dtWeekStart, sTodayID, iColumnWidth, iStartHour, iStartMin, iRow,
                                     iSlotLengthInMins, configArray ) {
                                                    // For each row of "possible appointments slot":
          var columnConfigArray = new Array();      // Build a new row array, containing several (column) cell items:
          var iWkDay = 0;
          for ( iWkDay=0; iWkDay < 6; iWkDay++ ) {
            var dtCurrDate  = iWkDay > 0 ? Ext.Date.add( dtWeekStart, Ext.Date.DAY, iWkDay ) : dtWeekStart;
            var iTotMins   = iStartHour * 60 + iStartMin + (iRow * iSlotLengthInMins);
            var iMinDigit  = iTotMins % 60;
            var iHourDigit = (iTotMins - iMinDigit) / 60;
            var sHourDigit = Ext.String.leftPad(iHourDigit,2,'0');
            var sMinDigit  = Ext.String.leftPad(iMinDigit,2,'0');
            var sBtnText   = sHourDigit + ':' + sMinDigit;
            var sCurrCellDT = Ext.Date.format(dtCurrDate, "Y-m-d") + ' ' + sBtnText;
            var sCurrDateID = Ext.Date.format(dtCurrDate, "Ymd");
            var sDate_UID   = sCurrDateID + sHourDigit + sMinDigit;
            var sDOM_UID    = "" + iWkDay + sHourDigit + sMinDigit;
            var dtCurrCell  = Ext.Date.parse( sCurrCellDT, "Y-m-d H:i" );
            var sCellBodyStyle = ( sCurrDateID == sTodayID ?
                                   "background-color: " + cssBgndEmptySlotTodayNormal + "; text-align: center; font: normal 12px verdana, sans-serif;" :
                                   "background-color: " + cssBgndEmptySlotNormal + "; text-align: center; font: normal 12px verdana, sans-serif;"
            );

            columnConfigArray.push({
              layout: 'absolute',
              bodyStyle: sCellBodyStyle,
              id: "cell" + sDOM_UID,
              width: iColumnWidth,
              height: iCellHeight,
              items: [
                {
                  xtype: 'image',
                  id: "imgPayed" + sDOM_UID,
                  src: '/images/icons/money.png',
                  hidden: true,
                  x: 3,
                  y: 2
                },
                {
                  xtype: 'image',
                  id: "imgReceipt" + sDOM_UID,
                  src: '/images/icons/email.png',
                  hidden: true,
                  x: 30,
                  y: 2
                },
                {
                  xtype: 'button',
                  id: "btn" + sDOM_UID,
                  dateUID: sDate_UID,
                  appointmentId: 0,
                  receiptId: 0,
                  text: sBtnText,
                  tooltip: "#{ I18n.t( :add_schedule_appointment, {:scope => [:appointment]} ) }",
                  x: iColumnWidth / 2 - 18,
                  y: 18,
                  handler: function( button ) {     // Invoke the actual handler on WeekPlannerPanel (the parent container):
                    var sYr = button.dateUID.substr( 0, 4);      // (format: "YmdHi")
                    var sMo = button.dateUID.substr( 4, 2);
                    var sDy = button.dateUID.substr( 6, 2);
                    var sHr = button.dateUID.substr( 8, 2);
                    var sMi = button.dateUID.substr(10, 2);
                    cmpPlannerGrid.getParentNetzkeComponent().processSlotClick( sYr, sMo, sDy, sHr, sMi, button.appointmentId, button.receiptId );
                  },
                  listeners: {
                    mouseover: function( thisBtn, ev, eOpts ) {
                      var sUID    = thisBtn.id.substr(3,6);       // (format: "btn"+weekday+"Hi")
                      var sDateID = thisBtn.dateUID.substr(0,8);  // (format: "YmdHi")
                      var cmp = Ext.getCmp( "cell" + sUID );
                      if ( cmp ) {
                      var sCellBackgnd = ""; 
                        if ( thisBtn.appointmentId > 0 )
                          sCellBackgnd = ( sDateID == sTodayID ? cssBgndUsedSlotTodayMouseover : cssBgndUsedSlotMouseover );
                        else
                          sCellBackgnd = ( sDateID == sTodayID ? cssBgndEmptySlotTodayMouseover : cssBgndEmptySlotMouseover );
                        cmp.body.dom.style.backgroundColor = sCellBackgnd;
                      }
                    },
                    mouseout: function( thisBtn, ev, eOpts ) {
                      var sUID    = thisBtn.id.substr(3,6);
                      var sDateID = thisBtn.dateUID.substr(0,8);
                      var cmp = Ext.getCmp( "cell" + sUID );
                      if ( cmp ) {
                        var sCellBackgnd = ""; 
                        if ( thisBtn.appointmentId > 0 )
                          sCellBackgnd = ( sDateID == sTodayID ? cssBgndUsedSlotTodayNormal : cssBgndUsedSlotNormal );
                        else
                          sCellBackgnd = ( sDateID == sTodayID ? cssBgndEmptySlotTodayNormal : cssBgndEmptySlotNormal );
                        cmp.body.dom.style.backgroundColor = sCellBackgnd;
                      }
                    }
                  }
                },
                {
                  xtype: 'container',
                  id: "lbl" + sDOM_UID,
                  style: "text-align: center; vertical-align: center;",
                  html: '',                           // (No patient names during setup)
                  y: 45,
                  margins: '2 2 2 2'
                }
              ]
// FIXME TODO ADD DragNDrop support
            });
          }
                                                    // Add the special "schedule notes" cell as a the last column:
          columnConfigArray.push({
            html: '',
            id: "notes" + sDOM_UID,
            width: iColumnWidth,
            height: iCellHeight,
            bodyStyle: "background-color: white; text-align: center; font: italic 1em arial,sans-serif; padding 5;"
          });
// DEBUG
//          console.log( 'Added notes cell <' + sDOM_UID + '>' );
                                                    // Add the whole row as a single container:
          configArray.push({
            layout: {
              type:  'hbox'
            },
            items: columnConfigArray
          });
        }

                                                    // == Actual Setup ==

        fBuildUpHeader( dtNewWeekStart, iCellWidth, cellConfigArray );
        var cellAMConfigArray = new Array();

        var iAmRow = 0;
        for ( iAmRow=0; iAmRow < iAmTotAppointments; iAmRow++ ) {
          fBuildUpRows( dtNewWeekStart, sTodayID, iCellWidth, iAmStartHour, iAmStartMin, iAmRow,
                        iAppointmentLength, cellAMConfigArray );
        }

        cellConfigArray.push({
          title: 'AM',
          collapsible: true,
          height: (iCellHeight + 2) * iAmTotAppointments + 25, // (add title border)
          layout: {
            type: 'fit'
          },
          items: [
            {
              layout: {
                type: 'vbox',
                align: 'stretch'
              },
              items: cellAMConfigArray
            }
          ]
        });

        var iPmRow = 0;
        var cellPMConfigArray = new Array();
        for ( iPmRow=0; iPmRow < iPmTotAppointments; iPmRow++ ) {
          fBuildUpRows( dtNewWeekStart, sTodayID, iCellWidth, iPmStartHour, iPmStartMin, iPmRow,
                        iAppointmentLength, cellPMConfigArray );
        }

        cellConfigArray.push({
          title: 'PM',
          collapsible: true,
          height: (iCellHeight + 2) * iPmTotAppointments + 25, // (add title border)
          layout: {
            type: 'fit'
          },
          items: [
            {
              layout: {
                type: 'vbox',
                align: 'stretch'
              },
              items: cellPMConfigArray
            }
          ]
        });

                                                    // Add widgets config dynamically to destination container:
        cmpPlannerGrid.add( cellConfigArray );
        cmpPlannerGrid.forceComponentLayout();
      }
    }
  JS
  # ---------------------------------------------------------------------------


  js_method :update_planner_range, <<-JS
    function( paramHash ) {
// XXX DEBUG:
//      console.log( '--- PlannerGrid::updatePlannerRange( paramHash ):' );
//      console.log( paramHash );
      var dtNewWeekStart = Ext.Date.parse( paramHash.weekStart, "Y-m-d" );
      var appointmentsArray = paramHash.appointments;
      var schedulesArray = paramHash.schedules;
      var sTodayID = Ext.Date.format( new Date(), "Ymd" );
                                                    // == HEADER update loop ==
      var iWkDay = 0;
      for ( iWkDay=0; iWkDay < 6; iWkDay++ ) {
        var dtCurrDate  = iWkDay > 0 ? Ext.Date.add( dtNewWeekStart, Ext.Date.DAY, iWkDay ) : dtNewWeekStart;
        var sCurrCellDay= saAbbrDayNames[ iWkDay ];
        var cmp = Ext.getCmp( "hdr" + iWkDay );
        var sCurrCellMonth = saAbbrMonthNames[ Ext.Date.format(dtCurrDate, "n") ];
        cmp.update( Ext.Date.format(dtCurrDate, "d ") + sCurrCellMonth + "<br/>" + sCurrCellDay );
      }
                                                    // == AM clearing loop ==
      var iRow = 0;
      for ( iRow=0; iRow < iAmTotAppointments; iRow++ ) {
        this.scanWeekCellsForClearing( dtNewWeekStart, sTodayID, iAmStartHour, iAmStartMin,
                                       iRow, iAppointmentLength );
      }
                                                    // == PM clearing loop ==
      for ( iRow=0; iRow < iPmTotAppointments; iRow++ ) {
        this.scanWeekCellsForClearing( dtNewWeekStart, sTodayID, iPmStartHour, iPmStartMin,
                                       iRow, iAppointmentLength );
      }

      this.updateCellsWith( dtNewWeekStart, sTodayID, appointmentsArray, schedulesArray );
    }
  JS
  # ---------------------------------------------------------------------------


  js_method :scan_week_cells_for_clearing, <<-JS
    function( dtWeekStart, sTodayID, iStartHour, iStartMin, iRow, iSlotLengthInMins ) {
                                                    // For each week day, retrieve the cell and clear its contents
      var iWkDay = 0;
      for ( iWkDay=0; iWkDay < 6; iWkDay++ ) {
        var dtCurrDate = iWkDay > 0 ? Ext.Date.add( dtWeekStart, Ext.Date.DAY, iWkDay ) : dtWeekStart;
        var iTotMins   = iStartHour * 60 + iStartMin + (iRow * iSlotLengthInMins);
        var iMinDigit  = iTotMins % 60;
        var iHourDigit = (iTotMins - iMinDigit) / 60;
        var sHourDigit = Ext.String.leftPad(iHourDigit,2,'0');
        var sMinDigit  = Ext.String.leftPad(iMinDigit,2,'0');
        var sCurrDateID = Ext.Date.format(dtCurrDate, "Ymd");
        var sDate_UID   = sCurrDateID + sHourDigit + sMinDigit;
        var sDOM_UID    = "" + iWkDay + sHourDigit + sMinDigit;
        var sCellBodyStyle = ( sCurrDateID == sTodayID ? cssBgndEmptySlotTodayNormal : cssBgndEmptySlotNormal );
        var cmp = Ext.getCmp( "cell" + sDOM_UID );
        if ( cmp ) {
          cmp.body.dom.style.backgroundColor = sCellBodyStyle;
          cmp = Ext.getCmp( "btn" + sDOM_UID );
          cmp.dateUID = sDate_UID;                  // Update the Button dateUID for this slot
          cmp.appointmentId = 0;                    // Clear the appointment and receipt id cached values
          cmp.receiptId = 0;
          cmp.setTooltip( "#{ I18n.t( :add_schedule_appointment, {:scope => [:appointment]} ) }" );
          cmp = Ext.getCmp( "lbl" + sDOM_UID );
          cmp.update('');
          cmp = Ext.getCmp( "imgPayed" + sDOM_UID );
          cmp.setVisible( false );
          cmp = Ext.getCmp( "imgReceipt" + sDOM_UID );
          cmp.setVisible( false );
        }
      }
                                                    // Notes column:
//      cmp = Ext.getCmp( "lbl" + sDOM_UID ); // (Label in Notes not used yet)
//      cmp.update('');
      cmp = Ext.getCmp( "notes" + sDOM_UID );
      cmp.update('');
    }
  JS


  js_method :update_cells_with, <<-JS
    function( dtWeekStart, sTodayID, appointmentsArray, schedulesArray ) {
                                                    // Update/fill with appointments data:
      Ext.Array.each( appointmentsArray, function( value, index, arrayItself ) {
// XXX DEBUG
//        console.log( 'Processing appointmentsArray: #' + index );
//        console.log( value );
                                                    // Get current date_schedule and compute which day of the week it is:
        var dtCurrDate = Ext.Date.parse(value.dateSchedule, "c");
        var millisElapsed = Ext.Date.getElapsed( dtWeekStart, dtCurrDate );
        var iWkDay = (millisElapsed - millisElapsed % 86400000) / 86400000;

        var iHourDigit = dtCurrDate.getUTCHours();
        var iMinDigit  = dtCurrDate.getUTCMinutes();
        var sHourDigit = Ext.String.leftPad(iHourDigit,2,'0');
        var sMinDigit  = Ext.String.leftPad(iMinDigit,2,'0');
                                                    // Quick check for valid appointments
        if ( (iMinDigit == 0 || iMinDigit == 30) &&
             (iHourDigit >= 8) && (iHourDigit < 21) ) {
          var sCurrDateID = Ext.Date.format(dtCurrDate, "Ymd");
          var sDOM_UID    = "" + iWkDay + sHourDigit + sMinDigit;

          var sCellBodyStyle = ( sCurrDateID == sTodayID ? cssBgndUsedSlotTodayNormal : cssBgndUsedSlotNormal );
          var cmp = Ext.getCmp( "cell" + sDOM_UID );
          if ( cmp ) {
            cmp.body.dom.style.backgroundColor = sCellBodyStyle;
          }

          cmp = Ext.getCmp( "btn" + sDOM_UID );
          if ( cmp ) {
            cmp.setTooltip( "#{ I18n.t( :edit_schedule_appointment, {:scope => [:appointment]} ) }" );
            cmp.appointmentId = value.id;             // Cache current appointment and receipt ID into the button members (will be used by click handler) 
            cmp.receiptId = value.receiptId; 
          }

          cmp = Ext.getCmp( "imgPayed" + sDOM_UID );
          if ( cmp ) {
            cmp.setVisible( value.isPayed );
          }

          cmp = Ext.getCmp( "imgReceipt" + sDOM_UID );
          if ( cmp ) {
            if ( value.receiptId > 0 ) {              // Check is_delivered from receipt, if present:
              if ( value.receipt.isDelivered )        // Update image source accordingly:
                cmp.setSrc( '/images/icons/email_open_image.png' );
              else
                cmp.setSrc( '/images/icons/email.png' );
            }
            cmp.setVisible( value.receiptId > 0 );
          }

          cmp = Ext.getCmp( "lbl" + sDOM_UID );
          if ( cmp ) {
            cmp.update( value.patient.surname + ' ' + value.patient.name );
          }
        }
        else {
          var sMsg = "#{ I18n.t(:invalid_appointment_found_at, {:scope=>[:appointment]}) }" +
                     Ext.Date.format(dtCurrDate, "#{ AGEX_FILTER_DATE_FORMAT_EXTJS }");
          cmpPlannerGrid.netzkeFeedback( sMsg );
        }
      });
                                                    // Update/fill with schedules data:
      var iSkippedNotes = 0;
      Ext.Array.each( schedulesArray, function( value, index, arrayItself ) {
// XXX DEBUG
//        console.log( 'Processing schedulesArray : #' + index );
//        console.log( value );
                                                    // --- AM Notes update ---
        if ( index < iAmTotAppointments + iSkippedNotes ) {
          if ( value.isDone ) {
            iSkippedNotes++;
          }
          else {                                    // Retrieve notes cell coordinate:
            var iTotMins = iAmStartHour * 60 + iAmStartMin + iAppointmentLength * (index - iSkippedNotes);
            var iMinDigit  = iTotMins % 60;
            var iHourDigit = (iTotMins - iMinDigit) / 60;
            var sHourDigit = Ext.String.leftPad(iHourDigit,2,'0');
            var sMinDigit  = Ext.String.leftPad(iMinDigit,2,'0');
            cmpPlannerGrid.updateNotesCell( value, sHourDigit, sMinDigit );
          }
        }                                           // --- PM Notes update ---
        else if ( (index >= iAmTotAppointments + iSkippedNotes) && 
                  (index < iPmTotAppointments + iSkippedNotes) ) {
          if ( value.isDone ) {
            iSkippedNotes++;
          }
          else {                                    // Retrieve notes cell coordinate:
            var iTotMins = iPmStartHour * 60 + iPmStartMin + iAppointmentLength * (index - iAmTotAppointments - iSkippedNotes);
            var iMinDigit  = iTotMins % 60;
            var iHourDigit = (iTotMins - iMinDigit) / 60;
            var sHourDigit = Ext.String.leftPad(iHourDigit,2,'0');
            var sMinDigit  = Ext.String.leftPad(iMinDigit,2,'0');
            cmpPlannerGrid.updateNotesCell( value, sHourDigit, sMinDigit );
          }
        }
      });
    }
  JS
  # ---------------------------------------------------------------------------


  js_method :update_notes_cell, <<-JS
    function( value, sHourDigit, sMinDigit ) {
      var sDOM_UID   = "5" + sHourDigit + sMinDigit;
// DEBUG
//      console.log( 'sDOM_UID=' + sDOM_UID + ', iSkippedNotes=' + iSkippedNotes );
                                                    // Prepare the content text:
      var sNote = ( value['patient'] ? (value.patient.surname + ' ' + value.patient.name) : '' );
      if ( value.mustCall ) {
        sNote = "#{ I18n.t(:must_call, {:scope=>[:schedule]}) } " + sNote;
      }
      if ( value.mustInsert ) {
        sNote = "#{ I18n.t(:must_insert, {:scope=>[:schedule]}) } " + sNote;
      }
      if ( value.mustMove ) {
        sNote = "#{ I18n.t(:must_move, {:scope=>[:schedule]}) } " + sNote;
      }
      if ( value['notes'] && value['notes'].length > 0 ) {
        sNote = sNote + ' ' + value.notes;
      }
                                                    // Update the note cell with content:
      var cmp = Ext.getCmp( "notes" + sDOM_UID );
      cmp.update( sNote );
    }
  JS


  private


################################################### FIXME REDO ALL D&D SUPPORT vvvv ###########

## TODO Remove old (now unused) d'n'd ruby grid definition code after it has been re-implemented in JS

 
  # Builds a single table row configuration for displaying a single appointments line in 
  # current week's schedule.
  #
  # The result is an array of Hash configurations for each cell.
  #
  # === Params:
  # curr_date     : Date instance for extracting current week
  # start_time    : DateTime instance representing work shift starting time
  # offset_min    : Integer offset in minutes from starting time
  # schedule      : schedule instance; it can be nil if the "schedule notes slot" is assumed to be empty for this row.
  # appointments_cache : a collection of all the Appointment instances of the current week.
  # dom_xref_hash : Hash containing all the lookup tables for DOM IDs, Appointment IDs, and empty-date place-holders' IDs.
  #                The hash will be filled during the construction of the table with several arrays, one for each cross-reference needed. 
  # user_can_edit, user_can_create : true only when current user can perform these action on this component
  #
  def OLD_CRAP_create_planner_config_for_row( curr_date, start_time, offset_min, schedule, appointments_cache,
                                     dom_xref_hash, user_can_edit=false, user_can_create=false )
    curr_tot_min = start_time.hour * 60 + start_time.min + offset_min
    curr_hour_digit = curr_tot_min / 60
    curr_min_digit = curr_tot_min % 60
    sTemp = "#{start_time.year.to_s}-" << "%02u" % start_time.month.to_s << "-" << 
            "%02u" % start_time.day.to_s << " " <<
            "%02u" % curr_hour_digit.to_s << ":" << "%02u" % curr_min_digit.to_s << ":00"
    curr_hour = DateTime.parse(sTemp)

    cfgResult = []
    dt_start = Schedule.get_week_start( curr_date )

                                                    # -- DAY CELL SLOT: add a table cell to the row for each working day:
    dt_start.step(dt_start+5, 1) { |d|
      curr_name = ""
      curr_updated_on = nil
      curr_id = 0
      curr_is_receipt_issued = false
      s_target_datetime = Schedule.format_datetime_coordinates_for_mysql_param( d, curr_hour )
      appointment = nil
# DEBUG
      puts "\r\n\r\n==================================[#{d.to_s}]========"

      for app in appointments_cache
# DEBUG
      puts "- Target: #{s_target_datetime} vs '#{app.date_schedule.to_s}'"
        if s_target_datetime == Schedule.format_datetime_for_mysql_param( app.date_schedule )
          curr_name = app.get_full_name
          curr_id = app.id
          curr_updated_on = app.updated_on
          curr_is_payed = app.is_payed?
          curr_is_receipt_issued = app.is_receipt_issued
          curr_is_receipt_delivered = app.is_receipt_delivered
# DEBUG
          puts "  Found #{curr_name}, app id:#{curr_id}."
          appointment = app
          break
        end
      end
                                                    # Build-up items configuration for the inner ExtJS table panel:
      cell_config = create_planner_cell_config( d, curr_hour, 0, appointment, user_can_edit, user_can_create )

                                                    # Make table cell data draggable or droppable, if we can:
      # if  curr_name.blank?                          # 'DROP'-appointment type:
        # div_id = get_unique_dom_id( 'dropapp', s_target_datetime )
        # table_data = content_tag( :div, table_data, :id => div_id ) + "\r\n"
        # if DRAG_N_DROP_GLOBAL_SWITCH && current_user && current_user.can_do(:appointments, :update)
          # table_data << content_tag( :script, get_droppable_script(div_id), :type => "text/javascript" ) + "\r\n"
          # dom_xref_hash[:drop_date_schedules]     << s_target_datetime
          # dom_xref_hash[:drop_date_schedule_doms] << div_id
        # end
                                                    # # 'DRAG'-appointment type:
      # elsif ! curr_is_receipt_issued
        # div_id = get_unique_dom_id( 'dragapp', s_target_datetime )
        # table_data = content_tag( :div, table_data, :id => div_id, :style => "width:100%; height:4em; background-color:inherit;" ) + "\r\n"
        # if DRAG_N_DROP_GLOBAL_SWITCH && current_user && current_user.can_do(:appointments, :update)
          # table_data << content_tag( :script, get_draggable_script(div_id) + get_highlight_script_if_recently_updated(div_id, curr_updated_on), :type => "text/javascript" ) + "\r\n"
          # dom_xref_hash[:drag_appointment_ids]  << curr_id
          # dom_xref_hash[:drag_appointment_doms] << div_id
        # end
                                                    # # 'FIXED'-appointment type:
      # else
        # div_id = get_unique_dom_id( 'app', s_target_datetime )
        # script_text = get_highlight_script_if_recently_updated( div_id, curr_updated_on )
        # table_data = content_tag( :div, table_data, :id => div_id ) + "\r\n"
        # unless script_text.blank?
          # table_data << content_tag( :script, script_text, :type => "text/javascript" ) + "\r\n"
        # end
      # end
                                                    # Encapsulate data in table cell:
      cfgResult << cell_config 
    }

                                                    # -- SCHEDULE NOTES SLOT: add another table cell at the end of the row:
    s_target_datetime = Schedule.format_datetime_coordinates_for_mysql_param( dt_start+6, curr_hour )
    schedule_notes_slot = ''

    # if schedule.nil?                                # 'DROP'-slot type:
        # div_id = get_unique_dom_id( 'dropslot', s_target_datetime )
        # schedule_notes_slot = content_tag( :div, '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;', :id => div_id ) + "\r\n"
        # if DRAG_N_DROP_GLOBAL_SWITCH && current_user && current_user.can_do(:appointments, :update)
          # schedule_notes_slot << content_tag( :script, get_droppable_script(div_id), :type => "text/javascript" ) + "\r\n"
          # dom_xref_hash[:drop_date_schedules]     << ''       # leave schedule date blank for empty side slots that are drop targets
          # dom_xref_hash[:drop_date_schedule_doms] << div_id
      # end
                                                    # # 'DRAG'-slot type:
    # elsif schedule.must_insert? and (! schedule.is_done?)
        # div_id = get_unique_dom_id( 'dragslot', s_target_datetime )
        # schedule_notes_slot = content_tag( :div, schedule.get_full_description(), :id => div_id, :style => "width:100%; height:4em; background-color:inherit;" ) + "\r\n"
        # if DRAG_N_DROP_GLOBAL_SWITCH && current_user && current_user.can_do(:appointments, :update)
          # schedule_notes_slot << content_tag( :script, get_draggable_script(div_id) + get_highlight_script_if_recently_updated(div_id, schedule.updated_on), :type => "text/javascript" ) + "\r\n"
          # dom_xref_hash[:drag_schedule_ids]  << schedule.id
          # dom_xref_hash[:drag_schedule_doms] << div_id
        # end
                                                    # # 'FIXED'-slot type:
    # else
      # div_id = get_unique_dom_id( 'slot', s_target_datetime )
      # schedule_notes_slot = content_tag( :div, schedule.get_full_description(), :id => div_id ) + "\r\n"
      # script_text = get_highlight_script_if_recently_updated( div_id, schedule.updated_on )
      # unless script_text.blank?
        # schedule_notes_slot << content_tag( :script, script_text, :type => "text/javascript" ) + "\r\n" 
      # end
    # end
#    cfgResult << "    #{content_tag( :td, schedule_notes_slot, :class => 'schedule-notes' )}\r\n"
    cell_config = create_planner_cell_config( dt_start+6, curr_hour, 0, nil, user_can_edit, user_can_create )
    cfgResult << cell_config

    return [{
      :layout => {
        :type  => 'hbox',
        :align => 'stretch',
        :pack  => 'start'
      },
      :items => cfgResult
    }]
  end
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
end
