require 'date'


=begin
  
= Format module

  - version:  3.00.12.20120204
  - author:   Steve A.

  Generic format utilities collection.

=end
module Format

  # Converts a +Float+ value to a +String+ representing an +Integer+ percentage.
  # (Ex.: 0.2 => " 20 %")
  #
  def self.float_to_percent( value, precision = 0, right_padding = 4 )
    sprintf( "%#{right_padding}.#{precision}f %", value.to_f * 100.0 )
  end

  # Converts a +Float+ value to a +String+ using variable precision format
  #
  def self.float_value( value, precision = 2, right_padding = 0 )
    sprintf( "%#{right_padding}.#{precision}f", value.to_f )
  end
  # ---------------------------------------------------------------------------
  #++


  # RegExp used to search for Integer-like values in formatted strings.
  INTEGER_STRING_SEARCH_REGEXP  = /(^|\s+)\-*\d+(\s+|$)/

  # RegExp used to search for Float-like values in formatted strings.
  FLOAT_STRING_SEARCH_REGEXP    = /(^|\s+)\-*\d+((\.|\,)\d+(e(\+|\-)\d+)?)?(\s+|$)/

  # RegExp used to search for Date-like values in formatted strings.
  DATE_STRING_SEARCH_REGEXP = /(^|\s+)(\d{1,4}(\-|\/|\.)\d{1,2}(\-|\/|\.)\d{1,4})\s*\w*\s*$/

  # RegExp used to search for Time-like values in formatted strings.
  TIME_STRING_SEARCH_REGEXP = /(^|\s+)\d+[\:\.]\d{1,2}([\:\.]\d{1,2})?(\s+|$)/

  # RegExp used to search for DateTime-like values in formatted strings.
  DATETIME_STRING_SEARCH_REGEXP = /(^|\s+)(\d{1,4}(\-|\/|\.)\d{1,2}(\-|\/|\.)\d{1,4})\,?\s*\d+[\:\.]\d{1,2}([\:\.]\d{1,2})?(\s+|$)/


  # Checks if an object can be converted to a valid Integer instance.
  # Returns false otherwise.
  #
  def self.could_be_an_integer?( an_object )
    return true if an_object.kind_of?( Integer )

    # If the tot. non-integer chars used in the string can be interpreted as "too much noise", we consider this
    # as a plain string: (any possible measure unit included in the string should be shorter than 6 chars,
    # as in '10000 US DOL.')
    int_char_count = an_object.to_s.count("-0123456789")
    str_size = an_object.to_s.size
    return false if (str_size > 2 * int_char_count) && (str_size - int_char_count > 8)

# DEBUG
#    puts "checking could_be_an_integer? '#{an_object}' for pattern match => #{ an_object.to_s =~ INTEGER_STRING_SEARCH_REGEXP }"
    return ! ( an_object.to_s =~ INTEGER_STRING_SEARCH_REGEXP ).nil?
  end

  # Checks if an object can be converted to a valid Float instance.
  # Returns false otherwise.
  #
  def self.could_be_a_float?( an_object )
    return true if an_object.kind_of?( Float )

    # If the tot. non-integer chars used in the string can be interpreted as "too much noise", we consider this
    # as a plain string: (any possible measure unit included in the string should be shorter than 6 chars,
    # as in '10000 US DOL.')
    int_char_count = an_object.to_s.count("-0123456789.")
    str_size = an_object.to_s.size
    return false if (str_size > 2 * int_char_count) && (str_size - int_char_count > 8)

# DEBUG
#    puts "checking could_be_a_float? '#{an_object}' for pattern match => #{ an_object.to_s =~ FLOAT_STRING_SEARCH_REGEXP }"
    return ! ( an_object.to_s =~ FLOAT_STRING_SEARCH_REGEXP ).nil?
  end

  # Checks if an object can be converted to a valid Date instance.
  # Returns false otherwise.
  #
  def self.could_be_a_date?( an_object )
    return true if an_object.kind_of?( Date )
# DEBUG
#    puts "checking could_be_a_date? '#{an_object}' for pattern match => #{ an_object.to_s =~ DATE_STRING_SEARCH_REGEXP }"
    return ! ( an_object.to_s =~ DATE_STRING_SEARCH_REGEXP ).nil?
  end


  # Checks if an object can be converted to a valid Time instance.
  # Returns false otherwise.
  #
  def self.could_be_a_time?( an_object )
    return true if an_object.kind_of?( Time )
    is_parsing_ok = false
    parsed_value = nil
    begin
      parsed_value = DateTime.parse( an_object.to_s.gsub(/\//,'-') )
      is_parsing_ok = parsed_value.kind_of?(DateTime)
    rescue
    end
# DEBUG
#    puts "checking could_be_a_time? '#{an_object}' for pattern match => #{ an_object.to_s =~ TIME_STRING_SEARCH_REGEXP }, parsing: #{ is_parsing_ok} (#{parsed_value})"
    return is_parsing_ok &&
           (! ( an_object.to_s =~ TIME_STRING_SEARCH_REGEXP ).nil?) &&
           ( an_object.to_s =~ DATE_STRING_SEARCH_REGEXP ).nil?
  end


  # Checks if an object can be converted to a valid DateTime instance.
  # Returns false otherwise.
  #
  def self.could_be_a_datetime?( an_object )
    return true if an_object.kind_of?( DateTime )
    is_parsing_ok = false
    parsed_value = nil
    begin
      parsed_value = DateTime.parse( an_object.to_s.gsub(/\//,'-') )
      is_parsing_ok = parsed_value.kind_of?(DateTime)
    rescue
    end
# DEBUG
#    puts "checking could_be_a_datetime? '#{an_object}' for pattern match => #{ an_object.to_s =~ TIME_STRING_SEARCH_REGEXP }, parsing: #{ is_parsing_ok} (#{parsed_value})"
    return is_parsing_ok &&
           (! ( an_object.to_s =~ DATETIME_STRING_SEARCH_REGEXP ).nil?)
  end


  # Check and converts any value to a localized string value (also parsable as CSV format).
  # (For example, using the defaults for floats in non-US locales: 5.23 => "5,23")
  #
  # === Parameters
  # - value : the value to be (localized and) formatted
  # - precision : floating point precision (floating point digits to be included)
  # - rjustification : minimum result string length required; spaces will be added if it's shorter
  # - time_format : format string for DateTime values or 'long' Time values
  # - date_format : format string for (short) Date values
  # - float_point_char : char to be used as floating point separator (useful for CSV automatic text import in external applications, which rely on current locale)
  #
  def self.to_localized_string( value, precision = 2, rjustification = 0,
                                time_format = '%d-%m-%Y %H:%M', date_format = '%d-%m-%Y',
                                float_point_char = '.' )
    if value.respond_to?('to_label')                # Retrieve association method to_label() value, if the value is an association column that responds to that method
      value.to_label().gsub(/[;]/,' -')             # sanitize strings (to_label should never return nil)

    elsif could_be_a_date?(value)
      Format.any_datetime( value, date_format )

    elsif could_be_a_datetime?(value)
      Format.any_datetime( value, time_format )
                                                    # If it's not already a Float but it could be an Integer, do it:
    elsif (! value.kind_of?(Float)) && Format.could_be_an_integer?(value)
      Format.float_value( value, 0, rjustification )
                                                    # Otherwise, if it's a numeric-like value, will probably be understood as a float:
    elsif value.kind_of?(Float) || Format.could_be_a_float?(value)
      fval = Format.float_value( value, precision, rjustification )
      fval.gsub!(/[.]/, float_point_char) if ( float_point_char != '.')
      fval
    else
      value.to_s.gsub(/[;]/,' -')                   # Avoid nil values and sanitize text for CSV format (with separator ';') parsing 
    end
  end
  # ---------------------------------------------------------------------------
  #++


  # Concatenates several values into a CSV-separated output line, terminated
  # by a line-feed + carriage return.
  #
  # Note that each value is converted to a string but is not checked for CSV-consistency;
  # that being said, each text value containing the same substring as the separator
  # will surely mess up the output from a parser's point of view.
  #
  def self.to_csv_line( array_of_values, separator )
    raise "Format.to_csv_line(): error: array_of_values must be an Array." unless array_of_values.instance_of?(Array)
    ( array_of_values.collect! {|e| e.to_s} ).compact.join( separator ) << "\r\n"
  end

  # Convert Ruport::Data::Table cells into CSV format.
  # Each row value is converted into string, separated by csv_separator and terminated
  # by a newline + carriage return characters.
  # Column header names are not processed, since globalized names are treated elsewhere.
  #
  def self.data_table_to_csv( ruport_table, csv_separator )
    str_result = ""

    ruport_table.each { |rec_row|
      s_a_result = []
      ruport_table.column_names.each { |name|
        s_a_result << ( rec_row[name].nil? ? "" : Format.to_localized_string(rec_row[name]) )
      }
      str_result << s_a_result.join(csv_separator) << "\r\n"
    }
    return str_result
  end
  # ---------------------------------------------------------------------------
  #++


  # Formats a date with a specified format using strftime().
  # If the passed value is a String instead of a valid DateTime instance,
  # it will be converted before formatting.
  #
  def self.any_datetime( datetime_value, str_format )
    return '' if datetime_value.nil?
    raise "Format.any_datetime(): received a null date format." if str_format.nil? || (str_format == '')

    if datetime_value.kind_of?( Time ) || datetime_value.kind_of?( Date ) || datetime_value.kind_of?( DateTime )
      return datetime_value.strftime(str_format)
    else                                          # If it's not a valid DateTime instance, try to parse it into one:
      begin
        return DateTime.parse( datetime_value.to_s.gsub(/\//,'-') ).strftime(str_format)
      rescue
        $stderr.print "*[E]* Format.any_datetime('#{datetime_value}'): invalid DateTime.parse() parameter specified!\r\n#{$!}\r\n"
        return DateTime.now.strftime(str_format)
      end
    end
  end

  # Formats a date using a default format of "day-mon-year" ("%d-%m-%Y").
  def self.a_date( datetime_value )
    Format.any_datetime( datetime_value, "%d-%m-%Y" )
  end

  # Formats a time using a default format of "hr:min" ("%d-%m-%Y").
  def self.a_time( datetime_value )
    Format.any_datetime( datetime_value, "%H:%M" )
  end

  # Formats a date using a default format of "day-mon-year, hr:min ("%d-%m-%Y %H:%M").
  def self.a_short_datetime( datetime_value )
    Format.any_datetime( datetime_value, "%d-%m-%Y %H:%M" )
  end

  # Formats a date using a default format of "day-mon-year, hr:min:sec" ("%d-%m-%Y %H:%M:%S").
  def self.a_datetime( datetime_value )
    Format.any_datetime( datetime_value, "%d-%m-%Y %H:%M:%S" )
  end
  # ---------------------------------------------------------------------------
  #++

  # Converts and formats a length expressed in a total count of seconds
  # in a more displayable string.
  def self.a_time_from_sec( seconds_value )
    ( (seconds_value / 60) > 0 ? ((seconds_value / 60).to_s.rjust(2)) << "\' " : "" ) << ((seconds_value % 60).to_s.rjust(2,'0')) << "\""
  end
  # ---------------------------------------------------------------------------
  #++
end
