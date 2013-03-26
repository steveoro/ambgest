#
# == Invoices Analysis Filtering Panel component implementation
#
# - author: Steve A.
# - vers. : 3.03.02.20130322, (Ambgest3 vers.)
#
# Similarly to FilteringDateRangePanel, this component allows to set a date range
# with two date pickers.
# The date pickers will take their initial values from the configuration of component.
#
# The filtering range will be applied to extract the dataset used for the invoicing
# analysis and the rendering of the charts.
#
# The filtering fields (as well as their component IDs) that define the filtering range
# parameters are named: (self-explanatory, with unique ID and symbol equal to their name)
#
# - <tt>filtering_date_start</tt>, a.k.a. <tt>InvoicesAnalysisFilteringPanel::FILTERING_DATE_START_CMP_ID</tt>
# - <tt>filtering_date_end</tt>, a.k.a. <tt>InvoicesAnalysisFilteringPanel::FILTERING_DATE_END_CMP_ID</tt>
#
class InvoicesAnalysisFilteringPanel < Netzke::Basepack::Panel

  # Component Symbol used to uniquely address the date-start field of the range
  FILTERING_DATE_START_CMP_SYM  = :filtering_date_start

  # Component ID used to uniquely address the date-start field of the range
  FILTERING_DATE_START_CMP_ID   = FILTERING_DATE_START_CMP_SYM.to_s

  # Component Symbol used to uniquely address the date-end field of the range
  FILTERING_DATE_END_CMP_SYM    = :filtering_date_end

  # Component ID used to uniquely address the date-end field of the range
  FILTERING_DATE_END_CMP_ID     = FILTERING_DATE_END_CMP_SYM.to_s


  js_properties(
    :prevent_header => true,
    :header => false
  )

  # Internal data stores:
  js_property :analysis_data_store_by_date
  # ---------------------------------------------------------------------------


  # Override this method to do stuff at the moment of first-time loading
  def before_load
# DEBUG
#    logger.debug( "\r\n========= conf: #{config.inspect} ===========\r\n" )
    if ( config[:override_filtering] )               # Do the 1-time override of the component session:
      component_session[FILTERING_DATE_START_CMP_SYM] = config[FILTERING_DATE_START_CMP_SYM]
      component_session[FILTERING_DATE_END_CMP_SYM]   = config[FILTERING_DATE_END_CMP_SYM]
      config[:override_filtering] = nil
    end
  end
  # ---------------------------------------------------------------------------


  def configuration
    super.merge(
      :persistence => true,                         # This allows to have a stored component session
      :frame => true,
      :width => "98%",
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
        {
          :fieldLabel => I18n.t(:graph_data_filtered_from, :scope => [:income_analysis]),
          :labelWidth => 200,
          :margin => '1 6 0 0',
          :id   => FILTERING_DATE_START_CMP_ID,
          :name => FILTERING_DATE_START_CMP_ID,
          :xtype => 'datefield',
          :vtype => 'daterange',
          :endDateField => FILTERING_DATE_END_CMP_ID,
          :width => 300,
          :enable_key_events => true,
          :format => AGEX_FILTER_DATE_FORMAT_EXTJS,
          :value => component_session[FILTERING_DATE_START_CMP_SYM] ||= super[FILTERING_DATE_START_CMP_SYM]
        },
        {
          :fieldLabel => I18n.t(:data_filtered_to, :scope => [:agex_action]),
          :labelWidth => 25,
          :margin => '1 2 0 6',
          :id   => FILTERING_DATE_END_CMP_ID,
          :name => FILTERING_DATE_END_CMP_ID,
          :xtype => 'datefield',
          :vtype => 'daterange',
          :startDateField => FILTERING_DATE_START_CMP_ID,
          :width => 125,
          :enable_key_events => true,
          :format => AGEX_FILTER_DATE_FORMAT_EXTJS,
          :value => component_session[FILTERING_DATE_END_CMP_SYM] ||= super[FILTERING_DATE_END_CMP_SYM]
        }
      ]
    )
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
              // Always return true since we are only using this vtype to set the
              // min/max allowed values (these are tested for after the vtype test)
              return true;
          }
      });

      this.addEventListenersFor( "#{FILTERING_DATE_START_CMP_ID}" );
      this.addEventListenersFor( "#{FILTERING_DATE_END_CMP_ID}" );
                                                    // Define the Models:
      Ext.define('InvoiceTotDataModel', {
          extend: 'Ext.data.Model',
          fields: [
            { name: 'date',         type: 'string' },
            { name: 'amount',       type: 'float' },
            { name: 'description',  type: 'string' }
          ]
      });
                                                    // Create the Data Store:
      analysisDataStoreByDate = Ext.create( 'Ext.data.Store', {
              storeId: 'storeAnalysisDataByDate',
              model: 'InvoiceTotDataModel'
          }
      );
      var currencyName = "#{ I18n.t(:amount_with_currency, {:scope=>[:receipt]}) }";
      this.createWeeklyInvoicingChart( currencyName );
      this.refreshAnalysisData({});
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
        function( field, value, eOpts ) {           // Retrieve values from both date controls:
          var sDateStart = this.getDateFor( "#{FILTERING_DATE_START_CMP_ID}" );
          var sDateEnd   = this.getDateFor( "#{FILTERING_DATE_END_CMP_ID}" );

          var opt = new Object;
          if ( sDateStart )
            opt[ "#{FILTERING_DATE_START_CMP_ID}" ] = sDateStart;
          if ( sDateEnd )
            opt[ "#{FILTERING_DATE_END_CMP_ID}" ] = sDateEnd;
                                                    // Call the endpoint to refresh (re-extract) data:
          if ( sDateStart && sDateEnd )
            this.refreshAnalysisData( opt );
        },
        this
      );

      fltrDate.on(                                  // Add listener on ENTER keypress:
        'keypress',
        function( field, eventObj, eOpts ) {
          if ( eventObj.getKey() == Ext.EventObject.ENTER ) {
            var sDateStart = this.getDateFor( "#{FILTERING_DATE_START_CMP_ID}" );
            var sDateEnd   = this.getDateFor( "#{FILTERING_DATE_END_CMP_ID}" );
            var opt = new Object;
            if ( sDateStart )
              opt[ "#{FILTERING_DATE_START_CMP_ID}" ] = sDateStart;
            if ( sDateEnd )
              opt[ "#{FILTERING_DATE_END_CMP_ID}" ] = sDateEnd;
                                                    // Call the endpoint to refresh (re-extract) data:
            if ( sDateStart && sDateEnd )
              this.refreshAnalysisData( opt );
          }
        },
        this
      );
    }
  JS
  # ---------------------------------------------------------------------------


  # Retrieves the current value of a filtering element.
  #
  js_method :get_date_for, <<-JS
    function( dateCtlName ) {                       // Retrieve the filtering date field sub-Component:
      var fltrDate = this.getComponent( dateCtlName );
      var sDate = false;
      try {
        var updatedValue = Ext.isString(fltrDate.getValue()) ? Ext.Date.parse( fltrDate.getValue(), "Y-m-d H:i" ) : fltrDate.getValue();
        sDate = Ext.Date.format( updatedValue, "#{AGEX_FILTER_DATE_FORMAT_EXTJS}" );
      }
      catch(e) {
      }
      return sDate;
    }
  JS
  # ---------------------------------------------------------------------------


  # Creates and renders the 'yearly invoicing' chart panel.
  #
  js_method :create_weekly_invoicing_chart, <<-JS
    function( currencyName ) {                      // Render Yearly-invoicing chart:
      Ext.create( 'widget.panel', {
          width: "98%",
          height: 250,
          renderTo: 'div_invocing_by_week_chart',
          layout: 'fit',
          items: {
            id: 'chartWeeklyInvoicing',
            xtype: 'chart',
            animate: true,
            shadow: true,
            store: analysisDataStoreByDate,
            axes: [
              {
                type: 'Numeric',
                position: 'left',
                fields: [ 'amount' ],
                title: currencyName,
                grid: {
                    odd: {
                        opacity: 1,
                        fill: '#ddd',
                        stroke: '#bbb',
                        'stroke-width': 1
                    }
                },
                minimum: 0,
                adjustMinimumByMajorUnit: 0,
                label: {
                    renderer: Ext.util.Format.numberRenderer('0,0'),
                    font: '10px Arial'
                }
              },
              {
                type: 'Category',
                position: 'bottom',
                fields: 'date',
                label: {
                    font: '10px Arial',
                    rotate: { degrees: 315 }
                }
              }
            ],
            series: [
                {
                  type: 'column',
                  axis: 'left',
                  highlight: true,
                  xField: 'date',
                  yField: [ 'amount' ],
                  tips: {
                      trackMouse: true,
                      minWidth: 210,
                      minHeight: 40,
                      renderer: function( storeItem, item ) {
                        this.setTitle( storeItem.get('date') );
                        this.update( storeItem.get('description') );
                      }
                  }
               },
                {
                  type: 'line',
                  axis: 'left',
                  xField: 'date',
                  yField: [ 'amount' ],
                  style: { opacity: 0.93 }
                }
            ]
          }
      });
      // ---------------------------------------------------------------- END of Weekly-invoicing Chart
    }
  JS
  # ---------------------------------------------------------------------------


  # Endpoint for refreshing the "invoice analysis" data store.
  #
  # Prepares the result hash of data that will be sent back to the internal Store
  # for the analysis charts and graphs.
  #
  # == Params (both are optional; when missing defaults to the component_session-saved range)
  # - filtering_date_start : an ISO-formatted (Y-m-d) date with which the grid scope can be updated
  # - filtering_date_end : as above, but for the ending-date of the range
  #
  endpoint :refresh_analysis_data do |params|
#    logger.debug( "--- refresh_analysis_data: #{params.inspect}" )
                                                    # Validate params (preparing defaults)
    if params[FILTERING_DATE_START_CMP_SYM]
      date_from_lookup = params[FILTERING_DATE_START_CMP_SYM]
      component_session[FILTERING_DATE_START_CMP_SYM] = date_from_lookup
    else
      date_from_lookup = component_session[FILTERING_DATE_START_CMP_SYM]
    end

    if params[FILTERING_DATE_END_CMP_SYM]
      date_to_lookup = params[FILTERING_DATE_END_CMP_SYM]
      component_session[FILTERING_DATE_END_CMP_SYM] = date_to_lookup
    else
      date_to_lookup = component_session[FILTERING_DATE_END_CMP_SYM]
    end

    currency_name = I18n.t(:currency, {:scope=>[:receipt]})
# DEBUG
#    logger.debug( "After validate:\r\n- date_from_lookup => #{date_from_lookup}" )
#    logger.debug( "- date_to_lookup => #{date_to_lookup}" )

    all_week_range = Schedule.get_all_week_ends_for_range( date_from_lookup, date_to_lookup )

    summary_array = []
    all_week_range.each_with_index { |week_range, index|
# DEBUG
#      logger.debug( "Processing week #{index} / #{all_week_range.size}, #{week_range[0]} ... #{week_range[1]}" )
      records = Receipt.find_all_receipts_for( week_range[0], week_range[1] )
                                                    # Compute the summary for each invoice in filtering range:
      amount = records.collect{|row| row.price.to_f }.sum

      description = records.collect{ |row|
        "<tr><td><i>#{row.get_receipt_header}:</i></td><td align='right'>#{sprintf('%.2f', row.price.to_f)} #{currency_name}</td></tr>"
      }.join('')

      summary_array << {
        :date => week_range[1].to_s,
        :amount => amount,
        :description => "<table align='center' width='95%'>#{description}<tr><td><hr/></td><td><hr/></td></tr><tr><td></td><td align='right'><b>#{sprintf('%.2f', amount)}</b> #{currency_name}</td></tr></table>"
      }
    }

    { :after_refresh_analysis_data => {
        :summary_by_date => summary_array,
        :currency => currency_name,
        :date_start => date_from_lookup,
        :date_end => date_to_lookup
      } 
    }
  end
  # ---------------------------------------------------------------------------


  # Handles the update of the refreshed data, passed as JSON result
  #
  js_method :after_refresh_analysis_data, <<-JS
    function( result ) {
      if ( result ) {                               // Retrieve parameters from result hash:
        var currencyName  = result['currency'];
        var summaryByDate = result['summaryByDate'];
        var sDateStart    = result['dateStart'];
        var sDateEnd      = result['dateEnd'];

        analysisDataStoreByDate.removeAll();

        var rowDataList = new Array();              // Store each row in a single array (thus adding data to the store triggers just 1 event)
        Ext.Array.each( summaryByDate, function( item, index, arrItself ) {
          rowDataList[ index ] = {
              date:         item.date,
              amount:       item.amount,
              description:  item.description
          };
        });
                                                    // Update / correct the filtering widgets:
        var fltrDate = this.getComponent( "#{FILTERING_DATE_START_CMP_ID}" );
        fltrDate.setValue( Ext.Date.parse(sDateStart.substr(0,10), "#{AGEX_FILTER_DATE_FORMAT_EXTJS}") );
        fltrDate = this.getComponent( "#{FILTERING_DATE_END_CMP_ID}" );
        fltrDate.setValue( Ext.Date.parse(sDateEnd.substr(0,10), "#{AGEX_FILTER_DATE_FORMAT_EXTJS}") );
                                                    // Loading the data will automatically update the chart:
        analysisDataStoreByDate.loadData( rowDataList );
      }
      else {
        this.netzkeFeedback( "#{I18n.t(:warning_no_data_to_send)}" );
      }
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
end
