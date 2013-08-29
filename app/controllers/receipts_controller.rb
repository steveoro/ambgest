class ReceiptsController < ApplicationController
  require 'common/format'
  require 'ruport'

  require 'receipt_layout'


  # Require authorization before invoking any of this controller's actions:
  before_filter :authorize


  # Default action
  def index
    ap = AppParameter.get_parameter_row_for( :receipts )
    @max_view_height = ap.get_view_height()
                                                    # Having the parameters, apply the resolution and the radius backwards:
    start_date = DateTime.now.strftime( ap.get_filtering_resolution )
                                                    # Set the (default) parameters for the scope configuration: (actual used value will be stored inside component_session[])
    @filtering_date_start  = ( Date.parse( start_date ) - ap.get_filtering_radius ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
    @filtering_date_end    = ( Date.parse( start_date ) + ap.get_filtering_radius ).strftime( AGEX_FILTER_DATE_FORMAT_SQL )
    @context_title = I18n.t(:receipts_list, {:scope=>[:receipt]})
  end
  # ---------------------------------------------------------------------------


  # Outputs a detailed report containing both the Receipt header and the selected rows,
  # specified with an array of ReceiptRow IDs.
  #
  # == Params:
  #
  # - <tt>:from</tt> => controller name used for redirection to the index action (default: 'receipts')
  #
  # - <tt>:type</tt> => the extension of the file to be created; one among: 'pdf', 'odt', 'txt', 'full.csv', 'simple.csv'
  #   (default: 'pdf')
  #
  # - <tt>:data</tt> (*required*) => a JSON-encoded array of Receipt IDs to be retrieved and processed
  #
  # - <tt>:is_internal_copy</tt> => when greater than 0, the output is considered as an "internal copy" (not original).
  #
  # - <tt>:use_alt_receipt_title</tt> => when not nil, the localized symbol <tt>:alt_receipt_title</tt> will be used instead of <tt>:receipt</tt>.
  #
  # - <tt>:date_from_lookup</tt> / <tt>:date_to_lookup</tt> => 
  #   String dates representing the starting and ending filter range for this collection of rows.
  #   Both are not required (none, one or both can be supplied as options).
  #
  # - <tt>:separator</tt> => text separator used only for data export; default: ';'
  #
  # - <tt>:layout</tt> => either 'flat' or 'tab' [default], to specify the export data layout used
  #   (both usable for CSV and TXT output files)
  #
  # - <tt>:no_header</tt> => when +true+, the header of the output will be skipped.
  #
  def report_detail
    logger.debug "\r\n!! ----- report_detail -----"
    logger.debug "report_detail: params #{params.inspect}"
                                                    # Parse params:
    id_list = ActiveSupport::JSON.decode( params[:data] ) if params[:data]
    unless id_list.kind_of?(Array)
      raise ArgumentError, "receipts_controller.report_detail(): invalid or missing data parameter!", caller
    end
    return if id_list.size < 1
# DEBUG
    logger.debug "receipts_controller.report_detail(): id list: #{id_list.inspect}"
                                                    # Retrieve the receipt rows from the ID list:
    records = nil
    begin
      records = Receipt.where( :id => id_list )
    rescue
      raise ArgumentError, "receipts_controller.report_detail(): no valid ID(s) found inside data parameter!", caller
    end
# DEBUG
    return if records.nil?
#    logger.debug "receipts_controller.report_detail(): records class: #{records.class}"
#    logger.debug "receipts_controller.report_detail(): records found: #{records.size}"

    filetype    = params[:type] || 'pdf'
    separator   = params[:separator] || ';'         # (This plus the following params are used only during data exports)
    use_layout  = (params[:layout].nil? || params[:layout].empty?) ? :tab : params[:layout].to_sym
    skip_header = (params[:no_header] == 'true' || params[:no_header] == '1')
                                                    # Obtain header row:
    header_record = records[0]
    if header_record.kind_of?( ActiveRecord::Base ) # == Init LABELS ==
      label_hash = {}                               # Initialize hash and extract all details column labels:
      (                                             # Extract all possible report labels: (only if not already present)
        header_record.serializable_hash.keys +
        Receipt.report_header_symbols() +
        Receipt.report_detail_symbols()
      ).each { |e|
        label_hash[e.to_sym] = I18n.t( e.to_sym, {:scope=>[:receipt]} ) unless label_hash[e.to_sym]
      }

                                                    # == DATA Collection ==
      report_data_hash = prepare_report_data_hash(
          header_record,
          records,
          label_hash,
          {
            :is_internal_copy       => params[:is_internal_copy],
            :use_alt_receipt_title  => params[:use_alt_receipt_title]
          }
      )

                                                    # == OPTIONS setup + RENDERING phase ==
      filename = create_unique_filename( report_data_hash[:report_base_name] ) + ".#{filetype}"

      if ( filetype == 'pdf' )                      # --- PDF ---
        options = {
          :date_from            => params[:date_from_lookup].to_s.gsub(/\'/,''),
          :date_to              => params[:date_to_lookup].to_s.gsub(/\'/,''),
          :title_justification  => :center,
          :title_width          => 220
        }.merge!( report_data_hash )
                                                    # == Render layout & send data:
        send_data(
            ReceiptLayout.render( options ),
            :type => 'application/pdf',
            :filename => filename
        )
        # -------------------------------------------

                                                    # --- TXT & DATA EXPORT formats ---
      else
        data = prepare_custom_export_data( report_data_hash, filetype, separator, use_layout, skip_header )
# DEBUG
#        puts data
        send_data( data, :type => "text/#{filetype}", :filename => filename )
        # -------------------------------------------
      end
                                                    # No valid data?
    else
      redirect_to( :controller => params[:from] || 'receipts', :action => :index )
    end
  end
  # ---------------------------------------------------------------------------


  private


  # Prepares the hash of data that will be used for report layout formatting.
  #
  # === Parameters:
  # - +header_record+ => Header (or parent entity) row associated with the current Model instance (or the first record of the list, if they are all the same entity)
  #
  # - +records+ => an ActiveRecord::Relation result to be processed as the main dataset
  #
  # - +label_hash+ => Hash container for all the text labels and strings that have been localized and are ready to be used
  #
  # === Additional options keys:
  # - <tt>:is_internal_copy</tt> => when not nil, the output is considered as an "internal copy" (not original).
  # - <tt>:use_alt_receipt_title</tt> => when not nil, the localized symbol <tt>:alt_receipt_title</tt> will be used instead of <tt>:receipt</tt>.
  #
  def prepare_report_data_hash( header_record, records, label_hash, options = {} )
    unless records.kind_of?( ActiveRecord::Relation )
      raise ArgumentError, "receipts_controller.prepare_report_data_hash(): invalid records parameter!", caller
    end
    unless header_record.kind_of?( ActiveRecord::Base )
      raise ArgumentError, "receipts_controller.prepare_report_data_hash(): invalid header_record parameter!", caller
    end
                                                    # == CURRENCY == Store currency name for later usage:
    currency_name  = 
    currency_short = header_record.get_currency_symbol

                                                    # Compute the report title and the base name for the file:
    if ( records.size == 1 )
      use_alt_title = ( options[:use_alt_receipt_title] ? :alt_receipt_title : nil )
      report_title     = header_record.get_title_names( use_alt_title ).join(" - ")
      report_base_name = header_record.get_base_name( use_alt_title ) + (options[:is_internal_copy] ? '_copy' : '')
    else
      report_title = "#{I18n.t( :receipts, {:scope=>[:receipt]} )} #{records.first.get_receipt_sortable_code()} ... #{records.last.get_receipt_sortable_code()}"
      report_base_name = "#{I18n.t( :receipts, {:scope=>[:receipt]} )}-#{records.first.get_receipt_sortable_code()}_#{records.last.get_receipt_sortable_code()}" + (options[:is_internal_copy] ? '_copy' : '')
    end
                                                    # == DATA COLLECTION == Creates header and detail arrays, with 1 item for each receipt that has to be printed
    header_data  = []
    detail_data  = []

    records.each { |row|
      header_data << row.prepare_report_header_hash( options[:use_alt_receipt_title] ? :alt_receipt_title : nil )
      detail_data << row.prepare_report_detail()
    }

    result_hash = {                                 # Prepare result hash:
      :report_title       => report_title,
      :report_base_name   => report_base_name,
      :is_internal_copy   => options[:is_internal_copy],
                                                    # Main data:
      :company_name       => 'Prof. LEONARDO ALLORO',
      :company_info       => "<i>Spec. Clinica delle Malattie Nervose e Mentali" <<
                             "\r\nSpec. Neuropsichiatria Infantile" <<
                             "\r\nDoc. Scienze Comportamento Umano" <<
                             "\r\n\"L.J.U.\" San Diego (U.S.A.)</i>" <<
                             "\r\nReggio Emilia: via G. Deledda, 1 42020, ALBINEA" <<
                             "\r\nParma: via Mazza, 2 - Tel. RE/PR: 0522.597370" <<
                             "\r\nPEC: leonardo.alloro@cgn.legalmail.it" <<
                             "\r\nNum. Albo Ordine dei Medici: 1095" <<
                             "\r\nC.F. LLR LRD 39L02 E922Y - P.IVA 00297970352",
      :footer_stamp       => I18n.t( :legal_stamp ),
      :footer_comments    => I18n.t( :footer_comments ),
      :footer_smallprint  => I18n.t( :footer_smallprint ),

      :label_hash         => label_hash,              # (This should be already translated and containing all the required label symbols)
      :header_data        => header_data,
      :detail_data        => detail_data,

      :currency_name      => header_record.get_currency_name,
      :currency_short     => header_record.get_currency_symbol,
      :privacy_statement  => I18n.t( :privacy_statement )
    }

    result_hash
  end
  # ----------------------------------------------------------------------------



  # Prepares the output text for any custom data export format
  #
  # == Parameters:
  # - <tt>report_data_hash</tt> => the output hash returned by <tt>prepare_report_data_hash()</tt>
  # - +filetype+ => the format of the output text ('txt', 'simple.csv', ...)
  # - +separator+ 
  # - <tt>use_layout</tt> => the symbol of the data export layout to be used (either <tt>:flat</tt> or <tt>:tab</tt> [default])
  #   (both usable for CSV and TXT output files)
  # - <tt>skip_header</tt> => when +true+, the header of the output will be skipped.
  #
  # === Supported parameters for <tt>report_data_hash</tt>:
  # All options returned by <tt>prepare_report_data_hash()</tt>, plus:
  # - <tt>:data_table</tt> => <tt>Ruport::Data::Table</tt> instance containing the data rows to be processed.
  # - <tt>:summary</tt> => hash of values as returned by <tt>prepare_summary_hash()</tt>.
  #
  #
  def prepare_custom_export_data( report_data_hash, filetype = 'txt', separator = ';',
                                  use_layout = :tab, skip_header = false )
    data = ''
                                                    # Check all supported layouts:
    if use_layout.to_sym == :tab
                                                    # --- REPORT HEADER: ---
      Receipt.report_detail_symbols().each { |key|
        data << "#{I18n.t(key, {:scope=>[:receipt]})}#{separator}"
      }
      data << "\r\n\r\n"
                                                    # Localize column names:
                                                    # --- DATA ---
      if ( filetype =~ /csv/ )
        report_data_hash[:detail_data].each_with_index{ |detail_data, idx|
          localize_ruport_table_column_names( detail_data, :receipt, report_data_hash[:label_hash] )
          data << "#{report_data_hash[:header_data][idx][:title]}#{separator}#{report_data_hash[:header_data][idx][:customer_name]}\r\n"
          data << detail_data.as( :csv, :format_options => {:col_sep => separator}, :ignore_table_width => true )
          data << "\r\n"
        }
      else
        report_data_hash[:detail_data].each_with_index{ |detail_data, idx|
          localize_ruport_table_column_names( detail_data, :receipt, report_data_hash[:label_hash] )
          data << "#{report_data_hash[:header_data][idx][:title]}#{separator}#{report_data_hash[:header_data][idx][:customer_name]}\r\n"
          data << detail_data.as( :text, :ignore_table_width => true, :alignment => :rjust )
          data << "\r\n"
        }
      end

    else                                            # == Any unsupported layout specified? ==
      # TODO ":flat" layout type (with no header) not needed yet
      data = "\r\n-- Unsupported layout format '#{use_layout}' specified! --\r\n\r\n"
    end

    data
  end
  # ---------------------------------------------------------------------------

end
