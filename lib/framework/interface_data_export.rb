require 'common/format'


=begin

= InterfaceDataExport

  - version:  3.00.02.20120204
  - author:   Steve A.

  Framework "interface" Module for commonly used Data-Export methods. To be included in any
  EntityBase sibling implementation.

  Refactored from the original EntityBase implementation.

=end
module InterfaceDataExport

  # Returns attribute values as an array composed by their values, using the subset of field
  # keys specified by data_symbols().
  #
  # Specifying a custom +export_syms+ Array allows to select a custom subset of instance columns to be exported.
  #
  def to_a( export_syms = self.class.data_symbols() )
    export_syms.collect do |sym|
      value = self.send( sym )
      fld_name = sym.to_s
                                                    # Check if it could be an association column:
      idx = ( fld_name =~ /_id\b/ )
      subentity_row = nil

      if ( value.kind_of?(ActiveRecord::Base) )
        subentity_row = value
      elsif idx
        subentity_row = self.send( fld_name[0..idx-1] )
      end

      if ( subentity_row )                          # If it's an association column, search and use a value getter:
        value_getter = [:name, :to_label, :get_full_name, :description ].detect { |getter| subentity_row.respond_to?(getter) }
        value = subentity_row.send( value_getter ) if value_getter
      end
      value = value.to_f if value.kind_of?(BigDecimal)
                                                    # If no optimal getter is rightly guessed, simply uses the default value obtained above:
      if block_given?
        value = yield value
      else
        value
      end
    end
  end


  # (Constant) Blank filler length of Floats converted to String values
  #
  CONVERTED_FLOAT2STRING_FIXED_LENGTH = 0

  # (Constant) precision of Floats converted to String values
  #
  CONVERTED_FLOAT2STRING_FIXED_PRECISION = 2

  # (Constant) Blank filler length of Floats converted to String percentages (including ' %')
  #
  CONVERTED_PERCENT2STRING_FIXED_LENGTH = 3


  # Similarly to +to_a()+, this returns all +data_symbols+ values as an Array, but with each
  # element converted to a string.
  #
  # Each attribute String value is formatted where possible to avoid conflicts
  # with all common CSV separators.(Mainly ';' for strings and '.' for floats.)
  # 
  # Specifying a custom +export_syms+ Array allows to select a custom subset
  # of instance columns to be exported.
  #
  # The date and time formats defaults used for this output are specified inside config/initializers/time_formats.rb 
  #
  def to_a_s( export_syms     = self.class.data_symbols(),
              precision       = CONVERTED_FLOAT2STRING_FIXED_PRECISION,
              rjustification  = CONVERTED_FLOAT2STRING_FIXED_LENGTH,
              datetime_format = Date::DATE_FORMATS[:agex_default_datetime],
              date_format     = Date::DATE_FORMATS[:agex_default_date],
              float_pnt_char  = '.' )
    to_a( export_syms ) { |value|
      Format.to_localized_string( value, precision, rjustification, datetime_format, date_format, float_pnt_char )
    }
  end


  # Returns attribute values as a (horizontal) line of string values joined by a separator.
  #
  # Specifying a custom +export_syms+ Array it's possible to select a subset
  # of instance columns to be exported.
  #
  def to_csv( separator = ";", export_syms = self.class.data_symbols() )
    to_a_s( export_syms ).join( separator )
  end


  # Returns attribute values as a (vertical) form-like list of header field labels with
  # their corresponding values converted to strings.
  #
  # Specifying a custom +export_syms+ Array it's possible to select a subset
  # of instance columns to be exported.
  #
  def to_txt( field_separator = ": ", line_separator = "\r\n", export_syms = self.class.data_symbols() )
    result = export_syms.dup
    values = to_a_s( export_syms )
    result.each_with_index { |sym, idx|
      result[idx] = "#{I18n.t( sym, {:scope => self.class.table_name.singularize.to_sym} )}#{field_separator}#{values[idx]}"
    }
    result.join( line_separator )
  end
  #----------------------------------------------------------------------------
  #++
end
#------------------------------------------------------------------------------
