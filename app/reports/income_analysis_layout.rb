# encoding: utf-8

=begin

== InvoiceRowLayout

- version:  3.03.02.20130322
- author:   Steve A.

=end
class IncomeAnalysisLayout
  require "ruport"
  require "prawn"
  require 'common/format'


  AUTHOR_STRING = 'AgeX5 - (p) FASAR Software, 2006-2013'


  # Prepares rendering options, default values and starts the rendering
  # process.
  #
  # == Options:
  # - <tt>:report_title<\tt> (required) =>
  #   a String description for the report title.
  #
  # - <tt>:label_hash<\tt> (required) =>
  #   Hash of all the possible (and already localized) string labels to be used as column heading titles or text labels in general.
  #   The keys of the hash should be symbols.
  #
  # - <tt>:data_table<\tt> (required) =>
  #   a collection of detail rows to be processed.
  #
  # - <tt>:summary_rows<\tt> (required) =>
  #   an Array of 2 row-arrays, containing the summarized totals of data_table, formatted using the same column alignment
  #
  # - <tt>:grouping_total<\tt>
  #     a verbose (String) representation of the total cost for all the collection detail rows computed using the parent row id.
  #
  # - <tt>:date_from<\tt>, <tt>:date_to<\tt>
  #     a String date representing the filtering range for this collection of rows.
  #
  def self.render( options = { :label_hash => {} } )
    options[:date_from] ||= ""
    options[:date_to] ||= ""
    options[:grouping_total] ||= ""

    options[:pdf_format] = {
      :page_size      => 'A4',
      :page_layout    => :portrait,
                                                    # Document margins (in PS pts):
      :left_margin    => 30,
      :right_margin   => 30,
      :top_margin     => 40,
      :bottom_margin  => 40,
                                                    # Metadata:
      :info => {
        :Title        => options[:report_title],
        :Author       => AUTHOR_STRING,
        :Subject      => options[:label_hash][ :meta_info_subject ],
        :Keywords     => options[:label_hash][ :meta_info_keywords ],
        :Creator      => "AmbGest3",
        :Producer     => "Prawn @ AgeX5 framework",
        :CreationDate => Time.now
      }
    }

    pdf = Prawn::Document.new( options[:pdf_format] )
    build_page_header( pdf, options )
    build_page_footer( pdf, options )
    build_report_body( pdf, options )
    finalize_standard_report( pdf )
    pdf.render()
  end 
  # ---------------------------------------------------------------------------


  protected


  # Builds and adds a page header on each page.
  #
  def self.build_page_header( pdf, options )
    pdf.repeat( :all ) do
      pdf.move_cursor_to( pdf.bounds.top() )
      pdf.text( "<i>#{AUTHOR_STRING}</i>", :align => :left, :size => 6, :inline_format => true )
      pdf.move_cursor_to( pdf.bounds.top() )
      pdf.text(
        "<i>#{options[:label_hash][:filtering_label]}: #{options[:date_from]} - #{options[:date_to]}</i>",
        { :align => :center, :size => 8, :inline_format => true } 
      )
      pdf.move_cursor_to( pdf.bounds.top() - 10 )
      pdf.stroke_horizontal_rule()
    end
  end
  # --------------------------------------------------------------------------


  # Builds and adds a page footer on each page.
  #
  def self.build_page_footer( pdf, options )
    pdf.repeat( :all ) do
      pdf.move_cursor_to( pdf.bounds.bottom() + 7 )
      pdf.stroke_horizontal_rule()
      pdf.text_box(
        "#{options[:label_hash][:report_created_on]}: #{Format.a_short_datetime( DateTime.now )}",
        :size => 6,
        :at => [50, 2],
        :width => pdf.bounds.width - 100,
        :height => 6,
        :align => :center
      )
      pdf.move_cursor_to( pdf.bounds.bottom() - 6 )
      pdf.stroke_horizontal_rule()
    end
  end
  # ---------------------------------------------------------------------------


  # Builds the report body, redifining also the margins to avoid overwriting on
  # page headers and footers.
  #
  def self.build_report_body( pdf, options )
# DEBUG
#    puts "\r\n-----------------------------------------"
#    puts "#{options[:data_table].inspect}"
#    puts "******** label_hash *********************"
#    puts "#{options[:label_hash].inspect}"
#    puts "---------- column names: ----------------"
#    puts "#{options[:data_table].column_names.inspect}\r\n"
                                                    # Table data & column names adjustments:
    table = options[:data_table]
    table.rename_columns { |col_name|
      options[:label_hash][col_name.to_sym] ? options[:label_hash][col_name.to_sym] : col_name.to_s
    } 

    table_array = [ table.column_names ]
    table_array += table.map { |row| row.to_a }
    table_array.map { |array|
      array.map! { |elem| elem.class != String ? elem.to_s : elem }
    }

                                                    # Adjust dynamic column widths:
    cw = pdf.bounds.width / 9
    cwsm = cw / 5
    fixed_column_widths = [
      cw+cwsm*2, cw+cwsm, cw/2+cwsm, cw-cwsm,
      cw+cwsm, cw+cwsm, cw/2+cwsm, cw, cw-cwsm
    ]
# DEBUG
#    puts "\r\n-- cw #{cw.inspect}"
#    puts "-- cwsm #{cwsm.inspect}"
#    puts "-- fixed_column_widths: #{fixed_column_widths.inspect}\r\n"
    whole_table_format_opts = {
      :header         => true,
      :column_widths  => fixed_column_widths
    }


    pdf.bounding_box( [0, pdf.bounds.height - 40],
                  :width => pdf.bounds.width,
                  :height => pdf.bounds.height-80 ) do
                                                    # -- Report title:
      pdf.text(
        "<u><b>#{options[:report_title]}</b></u>",
        { :align => :center, :size => 10, :inline_format => true } 
      )
      pdf.move_down( 10 )
                                                    # -- Main data table:
      pdf.table( table_array, whole_table_format_opts ) do
        cells.style( :size => 8, :inline_format => true, :align => :right )
        cells.style do |c|
          if c.content.empty? || c.content.nil?
            c.background_color = "ffffff"
            c.borders = []
          else
            c.background_color = (c.row % 2).zero? ? "ffffff" : "eeeeee"
          end
        end
        rows(0).style(
          :background_color => "c0ffc0",
          :text_color       => "00076d",
          :align            => :center,
          :size             => 7,
          :overflow         => :shrink_to_fit,
          :min_font_size    => 6
        )
      end
                                                    # -- Summary sub-table:
      pdf.table( options[:summary_rows], {:column_widths  => fixed_column_widths} ) do
        cells.style(
          :size => 8,
          :inline_format => true,
          :align => :right,
          :background_color => "ffffcc"
        )
      end
                                                    # -- Grouping total:
      pdf.move_down( 10 )
      pdf.text(
        "<b>#{options[:label_hash][ :grouping_total_label ]}: #{options[:grouping_total]} #{options[:currency_name]}</b>",
        { :align => :right, :size => 8, :inline_format => true } 
      )
    end
  end 
  # ---------------------------------------------------------------------------


  def self.finalize_standard_report( pdf )
    page_num_text = "Pag. <page>/<total>"
    numbering_options = {
      :at => [pdf.bounds.right - 150, 2],
      :width => 150,
      :align => :right,
      :size => 6
    }
    pdf.number_pages( page_num_text, numbering_options )
  end
  # ---------------------------------------------------------------------------
end