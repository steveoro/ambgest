# encoding: utf-8

=begin

== ReceiptLayout

- version:  3.03.02.20130322
- author:   Steve A.

=end
class ReceiptLayout
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
  # - <tt>:header_data<\tt> (required) =>
  #   an Hash of header fields for the layout.
  #
  # - <tt>:detail_data<\tt> (required) =>
  #   an instance of a Ruport::Data::Table (compiled from detail data rows) that has to be processed.
  #
  def self.render( options = { :header_data => [{}], :detail_data => [] } )
                                                    # Check the (complex) option parameters:
    raise "Invalid 'header_data' option parameter!" unless (
        options[:header_data].instance_of?(Array) && options[:header_data].size >= 1 &&
        options[:header_data][0].instance_of?(Hash) &&
        Receipt.report_header_symbols().all? { |e| options[:header_data][0].has_key?(e) }
    )
    raise "Invalid option parameters: the 'header_data' and 'detail_data' arrays must have the same size!" unless (
        options[:header_data].size == options[:detail_data].size
    )
    raise "Invalid 'detail_data' option parameter!" unless ( options[:detail_data].size >= 1 &&
        options[:detail_data][0].instance_of?(Ruport::Data::Table)
    )
    raise "Invalid 'label_hash' option parameter!" unless ( options[:label_hash].instance_of?(Hash) && options[:label_hash].size >= 1 )

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
    build_report_body( pdf, options )
    finalize_standard_report( pdf )
    pdf.render()
  end
  # -------------------------------------------------------------------------


  protected


  # Builds up the actual report body.
  #
  def self.build_report_body( pdf, options )
# DEBUG
#    puts "******************** label_hash *************************"
#    puts "#{options[:label_hash].inspect}"
#    puts "------------- detail_data[0], column names: -------------"
#    puts "#{options[:detail_data][0].column_names.inspect}"
#    puts "---------------------------------------------------------"

    options[:header_data].each_index { |idx|
# DEBUG
#      puts "Processing data row ##{idx + 1}, title: #{options[:header_data][idx][:title]}..." if (options[:header_data][0][:debug] == true)
      build_receipt_header( pdf, options, options[:header_data][idx] )
      build_receipt_subject( pdf, options, options[:header_data][idx] )
      build_receipt_body( pdf, options, options[:header_data][idx], options[:detail_data][idx] )
      build_receipt_footer( pdf, options )

      pdf.start_new_page(
        :size   => options[:pdf_format][ :page_size ],
        :layout => options[:pdf_format][ :page_layout ]
      ) unless idx == options[:header_data].size() - 1
    }
  end
  #---------------------------------------------------------------------------
  #++

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
  #---------------------------------------------------------------------------
  #++


  private


  def self.build_receipt_header( pdf, options, header_hash )
    pdf.stroke_color "0000cd"
    pdf.stroke_horizontal_rule()
    pdf.move_down(3)
    pdf.stroke_horizontal_rule()
    pdf.move_down(8)
                                                    # Logo:
    pdf.span( 240, :position => :left ) do
      pdf.fill_color "000000"
      pdf.text( "<b>#{options[:company_name]}</b>", :size => 12, :align => :center, :inline_format => true )
      pdf.text( options[:company_info], :size => 8, :align => :center, :inline_format => true )
    end

    pdf.move_down(8)
    pdf.stroke_color "0000cd"
    pdf.stroke_horizontal_rule()
    pdf.move_down(3)
    pdf.stroke_horizontal_rule()
                                                    # Title:
    pdf.move_up(70)
    pdf.indent( 300 ) do
      pdf.fill_color "000080"
      pdf.text( "<b>#{header_hash[:title]}</b>", :size => 20, :color => "000080", :align => :left, :inline_format => true )
      pdf.move_down(5)
      pdf.text( header_hash[:date_receipt], :size => 16, :color => "000080", :align => :left, :inline_format => true )
    end
    pdf.move_down(60)
  end
  # ---------------------------------------------------------------------------


  def self.build_receipt_subject( pdf, options, header_hash )
    line1_y = line2_y = line3_y = 0

    pdf.indent( 10 ) do
      pdf.fill_color "000080"
      line1_y = pdf.cursor()
      pdf.text( "#{options[:label_hash][:customer_name]}:", :size => 10, :color => "000080", :align => :left )
      pdf.move_down(10)
      line2_y = pdf.cursor()
      pdf.text( "#{options[:label_hash][:customer_info]}:", :size => 10, :color => "000080", :align => :left )
      pdf.move_down(10)
      line3_y = pdf.cursor()
      # Check for a variable label override inside the header_hash (this can change from page to page, when the override is found):
      variable_tax_code_label = header_hash[:customer_tax_code_label] ? header_hash[:customer_tax_code_label] : options[:label_hash][:customer_tax_code]
      pdf.text( "#{variable_tax_code_label}:", :size => 10, :color => "000080", :align => :left )
    end
                                                    # Subject data:
    pdf.indent( 90 ) do
      pdf.fill_color "000000"
      pdf.move_cursor_to( line1_y + 2 )
      pdf.text( "<b>#{header_hash[:customer_name]}</b>", :size => 12, :color => "000000", :align => :left, :inline_format => true )
      pdf.move_cursor_to( line2_y + 2 )
      pdf.text( "#{header_hash[:customer_info]}", :size => 12, :color => "000000", :align => :left )
      pdf.move_cursor_to( line3_y + 2 )
      pdf.text( "#{header_hash[:customer_tax_code]}", :size => 12, :color => "000000", :align => :left )
    end
  end
  # ---------------------------------------------------------------------------


  def self.build_receipt_body( pdf, options, header_hash, detail_data )
    pdf.move_cursor_to( pdf.bounds.height - 210 )
                                                  # Table data & column names adjustments:
    table = detail_data
    table.rename_columns { |col_name|
      options[:label_hash][col_name.to_sym] ? options[:label_hash][col_name.to_sym] : col_name.to_s
    } 

    table_array = [ table.column_names ]
    table_array += table.map { |row| row.to_a }
    table_array.map { |array|
      array.map! { |elem| elem.class != String ? elem.to_s : elem }
    }

    # Column width array, containing the exact column width in PDF measure units for each column
    #
    fixed_column_widths = [
       40,                                          # :qty
       330,                                         # :description
       73,                                          # :percent
       80                                           # :amount
    ]
    whole_table_format_opts = {
      :header         => true,
      :column_widths  => fixed_column_widths
    }


    pdf.bounding_box( [0, pdf.cursor()],
                  :width => pdf.bounds.width,
                  :height => pdf.bounds.height / 2 - 80 ) do
                                                    # -- Main data table:
      pdf.table( table_array, whole_table_format_opts ) do
        cells.style( :size => 8, :inline_format => true )
        cells.row(1..-2).borders = [:left, :right]
                                                    # Set alignment according to cell column:
        cells.style do |c|
          if c.column == 1 && c.row > 0
            c.align = :left
          else
            c.align = :right
          end
          c.background_color = (c.row % 2).zero? ? "FFFFE0" : "EEE8AA"
        end
                                                    # Header style override:
        rows(0).style(
          :background_color => "000080",
          :text_color       => "ffffff",
          :align            => :center,
          :size             => 7
        )
      end
    end

                                                    # Notes:
    pdf.move_cursor_to( pdf.bounds.height() / 2 + 50 )
    pdf.stroke_color "0000cd"
    pdf.indent( 10 ) do
      pdf.text( "#{options[:label_hash][:customer_notes]}:", :size => 10, :color => "000000", :align => :left, :inline_format => true )
    end
    pdf.move_up( 12 )
    pdf.indent( 50 ) do
      pdf.text( "#{header_hash[:customer_notes]}:", :size => 12, :color => "000000", :align => :left, :inline_format => true )
    end

                                                    # Copy watermark:
    if options[:is_internal_copy]
      pdf.move_down(40)
      pdf.text( "<i>#{options[:label_hash][:copy_watermark]}</i>", :align => :center, :size => 10, :inline_format => true )
      pdf.move_up(40)
    end

                                                    # Signature space:
    pdf.move_cursor_to( pdf.bounds.bottom() + 250 )
    pdf.stroke_horizontal_rule()
    pdf.move_down(20)
    pdf.indent( 10 ) do
      pdf.text( "#{options[:label_hash][:customer_signature]}:",  :size => 10 )
    end
  end
  # ---------------------------------------------------------------------------


  def self.build_receipt_footer( pdf, options )
    pdf.move_cursor_to( pdf.bounds.bottom() + 170 )
    pdf.stroke_color "0000cd"
    pdf.move_down(10)
    pdf.stroke_horizontal_rule()
    pdf.move_down(2)
    pdf.stroke_horizontal_rule()
                                                    # Print stamp
    pdf.move_down(33)
    pdf.stroke_color "bebebe"
    line_y = pdf.cursor()
    pdf.move_cursor_to( line_y )
    pdf.rectangle(
        [ pdf.bounds.right() - 160, line_y + 20 ],
        160,
        120
    )

    pdf.move_cursor_to( line_y - 40 )
    pdf.fill_color "bebebe"
    pdf.indent( pdf.bounds.right() - 160 ) do
      pdf.text(
          options[:footer_stamp],
          :size => 10,
          :align => :center
      )
    end
                                                    # Footer comments
    pdf.move_cursor_to( line_y )
    pdf.fill_color "000000"
    pdf.indent( 16 ) do
      pdf.text( options[:footer_comments], :size => 10, :color => "000000" )
    end
    pdf.move_down(10)
    pdf.indent( 16 ) do
      pdf.text( options[:footer_smallprint],  :size => 8, :color => "000000" )
    end
                                                    # Page trailer
    pdf.move_cursor_to( pdf.bounds.bottom() + 10 )
    pdf.stroke_color "0000cd"
    pdf.stroke_horizontal_rule()
    pdf.move_down(4)
    pdf.fill_color "bebebe"
    pdf.indent( 4 ) do
      pdf.text( '<i>AmbGest3 - (p) FASAR Software 2006-2013</i>',  :size => 6, :color => "bebebe", :inline_format => true )
    end
  end
  # ---------------------------------------------------------------------------
end
# =============================================================================
