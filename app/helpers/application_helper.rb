module ApplicationHelper

  # Formats a long text as HTML presentation-ready, using paragraph tags and line breaks on line endings.
  def format_longtext( text_value )
    "<span class='long-text'>" << h( text_value ).gsub( /\[/, "<p/>[" ).gsub( /$/, "<br/>" ) << "</span>"
  end


  # Formats a "monospaced" text with right justification, using HTML non-blockable spaces ("&nbsp;")
  # for a predetermined maximum width of characters.
  #
  # Example:
  # rjust_nbsp( "100.0", 8 ) => "&nbsp;&nbsp;&nbsp;100.0"
  #
  def rjust_nbsp( text_value, max_width )
    n = max_width - h( text_value ).length
    ("&nbsp;" * (n > 0 ? n : 0)) << h( text_value )
  end
  # ----------------------------------------------------------------------------
  #++


  # Generates a readonly HTML checkbox control for display purposes only
  #
  def show_chkbox( is_checked, checked_image_name = "/images/icons/tick.png", unchecked_image_name = "/images/icons/bullet_toggle_minus.png" )
    is_checked ? image_tag(checked_image_name, {:alt => "[X]"}) : image_tag(unchecked_image_name, {:alt => "[_]"})
  end

  # Generates a small tick image for HTML display if the bool_value is true,
  # also using the supplied resource name string if not null. (Defaults to a small
  # tick image, "tick.png" if the image_name parameter is left empty)
  # No path is needed if stored under "public/images".
  #
  def show_tag( bool_value, image_name = "/images/icons/tick.png" )
    bool_value ? image_tag(image_name, {:alt => "X"}) : ''
  end
  # ----------------------------------------------------------------------------
  #++

  # Generates an ExtJS Button widget configuration to be used inside an items list of
  # a panel container.
  #
  # == Params:
  #
  # <tt>action_title_i19n_sym</tt> => Symbol for the I18n title for the button. The method assumes also that
  #                                   a tooltip symbol is defined with a "_tooltip" appended on the title symbol
  # <tt>action_title_i19n_scope_sym</tt> => Symbol for the I18n scope of the localization;
  #                                         it can be nil for using the default global scope
  # <tt>location_href_path</tt> => URL path to be executed upon button click 
  # <tt>image_name</tt> => file name for the image to be used in the button, searched under "/images/icons"
  #
  def create_extjs_button_config( action_title_i19n_sym, action_title_i19n_scope_sym,
                                  location_href_path, image_name = "cog.png" )
    action_text  = I18n.t( action_title_i19n_sym.to_sym, {:scope => [action_title_i19n_scope_sym ? action_title_i19n_scope_sym.to_sym : nil]} )
    tooltip_text = I18n.t( "#{action_title_i19n_sym}_tooltip".to_sym, {:scope => [action_title_i19n_scope_sym ? action_title_i19n_scope_sym.to_sym : nil]} )
    action_text.gsub!(/'/,'_')                      # Safety quote removal to avoid JS parsing errors
    tooltip_text.gsub!(/'/,'_')

    raw <<-JS
      {
        xtype: 'button',
        icon: '/images/icons/#{ image_name }',
        text: "#{ action_text }",
        tooltip: "#{ tooltip_text }",
        margin: '0 3 3 3',
        handler: function() {
          location.href = "#{ location_href_path }";
        }
      }
    JS
  end
  # ----------------------------------------------------------------------------
end
