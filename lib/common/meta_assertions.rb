=begin
  
= MetaAssertions

  - version:  2.50.10.20100512
  - author:   Steve A.

  Container module for generic meta assertions.

=end
module MetaAssertions

  # Checks if an object is any kind of Numeric, Bignum or BigDecimal class.
  # Returns false otherwise.
  #
  def self.is_numeric?( an_object )
    return( an_object.kind_of?( Numeric ) || an_object.kind_of?( Bignum ) ||
            an_object.kind_of?( BigDecimal ) )
  end
  #-----------------------------------------------------------------------------
  #++

  # Checks if an object is a non-nil and non-empty string text.
  # Returns false otherwise.
  #
  def self.is_a_non_empty_string?( an_object )
    return an_object.kind_of?( String ) && (! an_object.nil?) &&
           (an_object != '') && (an_object.length > 0)
  end

  # Checks if each item inside an array is a non-nil and non-empty string value.
  # Returns false otherwise.
  #
  def self.each_item_is_a_non_empty_string?( an_array )
    return an_array.kind_of?( Array ) &&
			     an_array.all? { |e| self.is_a_non_empty_string?(e) }
  end
  #-----------------------------------------------------------------------------
  #++

  # Checks that the specified list is not empty.
  #
  def self.is_a_non_empty_hash( an_hash )
    not_empty_list_check( an_hash, Hash, :kind_of? )
  end

  # Checks that the specified list is not empty.
  #
  def self.is_a_non_empty_array( an_array )
    not_empty_list_check( an_array, Array, :kind_of? )
  end
  #-----------------------------------------------------------------------------
  #++

  # Checks if enumerable B is contained inside enumerable A, regardless of sort order or duplicate elements.
  # Returns false otherwise.
  #
  def self.contains?( enum_a, enum_b )
    enum_b.all? {|e| enum_a.include?(e) }
  end

  # Checks if two arrays have same +Comparable+ items (same number and type), indipendently from sort order.
  # Returns false otherwise.
  #
  def self.have_same_items?( array_a, array_b )
    return array_a.kind_of?( Array ) && array_b.kind_of?( Array ) &&
           ( array_a.sort {|v,w| v.to_s <=> w.to_s} == array_b.sort {|x,y| x.to_s <=> y.to_s} )
  end
  #-----------------------------------------------------------------------------
  #++

  # Checks if *each* item inside an array is an <tt>instance_of?( a_klass )</tt>.
  # Returns false otherwise (if any element is not of the same class).
  #
  def self.each_item_is_a?( an_array, a_klass )
    each_item_send_to( an_array, a_klass, :instance_of? )
  end

  # Checks if *each* item inside an array is a <tt>kind_of?( a_klass )</tt>.
  # Returns false otherwise (if any element does not belong to the same class hierachy).
  #
  def self.each_item_is_somekind_of?( an_array, a_klass )
    each_item_send_to( an_array, a_klass, :kind_of? )
  end

  # Checks if *each* item inside an array is a string value (even if it is empty).
  # Returns false otherwise.
  # Shortcut method for MetaAssertions.each_item_is_a?( an_array, String )
  #
  def self.each_item_is_a_string?( an_array )
    return self.each_item_is_a?( an_array, String )
  end
  #-----------------------------------------------------------------------------
  #++


  private


  # Checks that the specified list is of type +a_klass+ and is not empty.
  #
  def self.not_empty_list_check( an_enumeration, a_klass, a_method_symbol_or_name )
    return an_enumeration.send( a_method_symbol_or_name.to_sym, a_klass ) &&
           ( an_enumeration.size > 0 )
  end

  # Checks that all items of the specified Array list can send invoked successfully
  # with the specified method +a_method_symbol_or_name+, having +a_klass+ as parameter.
  #
  def self.each_item_send_to( an_array, a_klass, a_method_symbol_or_name )
    return an_array.kind_of?( Array ) &&
           an_array.all? { |e| e.send( a_method_symbol_or_name.to_sym, a_klass ) }
  end
end