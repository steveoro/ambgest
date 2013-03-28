# encoding: utf-8

class ApplicationController < ActionController::Base
  protect_from_forgery

  # Pick a unique cookie name to distinguish our session data from others'
#  ActionController::Base.session_options[:session_key] = '_' + AGEX_APP + '_session_id'

  before_filter :set_locale


  # Set the default URL options:
  def default_url_options( options={} )
    logger.debug "default_url_options is passed options: #{options.inspect}\n"
    { :locale => I18n.locale }
  end


  # ###########################################################################
  # -- Error/Mailing management tools --
  # 


  # Set this to true to enable double logging (both the logger variable and stdout will be used).
  DEBUG_VERBOSE_ON_CONSOLE = false unless defined?(DEBUG_VERBOSE_ON_CONSOLE)


  # Just logs the specified output message using either WARN or ERROR level logging,
  # with no subsequent redirection being made.
  #
  # When an exception has been intercepted and the variable $! has been set,
  # the level will be set to ERROR (defaults to WARN).
  #
  def log_error( output_message, verbose_trace = true )
    if $!.nil?                                      # When there's no exception, just use the INFO level:
      msg = "[W!]-- #{output_message}"
      puts( msg ) if DEBUG_VERBOSE_ON_CONSOLE       # (When no logging facility is enabled, this flag will generate an output on console)
      logger.warn( msg )
    else
      msg = "[E!]-- ERROR INTERCEPTED: #{output_message}"
      error_description = $!
      error_trace = $@.join("\r\n")
      user = current_user()
      user = user ? user.get_full_name : '(user not logged in yet)'

      if DEBUG_VERBOSE_ON_CONSOLE
        puts( msg )
        puts( error_description )
      end
      logger.error( msg )
      logger.error( error_description )
                                                    # Send a message to the developers anyway:
      begin
        AgexMailer.exception_mail( user, error_description, error_trace ).deliver
        logger.info("[*I*]- error report e-mail allegedly sent.")
      rescue
        logger.warn( '[W!]-- Unable to send out error report e-mail message, Mailer not responding or not configured properly yet.' )
      end
                                                    # If the verbose trace is enabled, log it:
      if verbose_trace
        puts( error_trace ) if DEBUG_VERBOSE_ON_CONSOLE
        logger.error( error_trace )
      end
    end
  end


  # Sends out an e-mail to notify the developers of important actions by the users
  # taking place during app usage.
  #
  def log_action( action_performed, action_description )
    user = current_user()
    user = user ? user.get_full_name : '(user not logged in yet)'
    logger.info("[*I*]- ACTION: '#{action_performed}' by #{user}: #{action_description}.")
                                                  # Send a message to the developers anyway:
    begin
      AgexMailer.action_notify_mail( user, action_performed, action_description ).deliver
      logger.info("[*I*]- action-notify e-mail allegedly sent.")
    rescue
      logger.warn( '[W!]-- Unable to send out action-notify mail message, Mailer not responding or not configured properly yet.' )
    end
  end
  # ---------------------------------------------------------------------------


  # ###########################################################################
  # -- Misc (controller-related) utility methods: --
  # 


  # Creates a unique filename minus the extension from any text, by default appending also
  # a date and time string signature at the end.
  #
  def create_unique_filename( text_value, suffix = DateTime.now.strftime("_%Y%m%d_%H%M") )
    text_value.gsub(/[òàèùçé^!"'£$%&?.,;:§°<>]/,'').gsub(/[\s|]/,'_').gsub(/[\\\/=]/,'-') + suffix
  end
  # ---------------------------------------------------------------------------


  # Utility method to localize the column names of a <tt>Ruport::Data::Table</tt> instance,
  # given the main Model symbol used to scope its localization labels,
  # and an existing +label_hash+ of already localized text labels (if any).
  #
  # == Parameters:
  # - <tt>ruport_table</tt> => the table with the column names that have to be localized
  # - <tt>model_sym</tt> => symbol representing the scope of the localization labels (i.e.: <tt>ProjectRow</tt> #=> <tt>:project_row</tt>)
  # - <tt>label_hash</tt> => the Hash of already localized labels
  #
  def localize_ruport_table_column_names( ruport_table, model_sym, label_hash = {} )
    return unless ruport_table.kind_of?( Ruport::Data::Table ) && label_hash.kind_of?( Hash )
                                                    # Localize each column name:
    ruport_table.column_names().each { |col_name|
      if label_hash.has_key?(col_name.to_sym)
        ruport_table.rename_column( col_name, label_hash[col_name.to_sym] )
      else
        ruport_table.rename_column( col_name, I18n.t( col_name.to_sym, {:scope=>[model_sym.to_sym]} ) )
      end
    }
  end
  # ----------------------------------------------------------------------------
  #++

  # Retrieves default firm id; mainly used as a filtering parameter or for defaults.
  # Current user will be checked for a default firm id; if not found, a default id will be searched
  # in app_parameters dedicated row value.
  # The result can also be null or 0 if the default firm parameter has not been set up yet.
  #
  def get_default_firm_id()
    if user = current_user
      user.firm_id ? user.firm_id : AppParameter.get_default_firm_id()
    else
      AppParameter.get_default_firm_id()
    end
  end
  # ----------------------------------------------------------------------------
  #++



  protected



  # Returns current user object.
  #
  def current_user
    session[:le_user_id] ? LeUser.find_by_id(session[:le_user_id]) : nil
  end
  # ----------------------------------------------------------------------------

  # Removes older (automatically generated) files from the public output directory
  # on the server.
  #
  def clean_old_output()
    deletable_filenames = []
    wd = FileUtils.pwd()
    all_filenames = ['/public/output/*'].collect!{|e| Dir.glob(wd + e)}.flatten.compact
# DEBUG
#    puts "\r\n=== Cleaning old output files:"
#    puts "Found #{all_filenames.size} files (either new or old). Checking last access times..."

    all_filenames.each { |filename|                 # For each filename found, check if it is old enough to be removed:
      last_access_time = File.open(filename).atime
      dt = DateTime.new( last_access_time.year, last_access_time.month, last_access_time.day, last_access_time.hour, last_access_time.min, last_access_time.sec )
      diff = DateTime.now - dt
      hrs, min, sec, millis = Date.day_fraction_to_time(diff)
# DEBUG
#      puts "'#{filename}': #{hrs}h #{min}m #{sec}s"
      if ( min > 2 )                                # (Streaming should take less than 2 mins)
        deletable_filenames << filename
      end
    }
# DEBUG
#    puts "Found #{deletable_filenames.size} old files. Erasing them..."
                                                    # Kill'em all:
    FileUtils.rm_f( deletable_filenames )
  end
  # ----------------------------------------------------------------------------


  private


  # Set current locale either from URL +locale+ parameter or from the default I18n value
  # 
  # Will set the cookie 'locale' if (and only if) an explicit parameter 'locale'
  # is passed (and is acceptable) or it is explicitly specified by the locale part of the URL.
  # (Check out routes.rb for locale detection inside the URL request)
  #
  # - If no parameter or URL part specifies the locale, the cookie is used (if it exists)
  # - If no cookie exists, we look through the list of desired languages for the
  #   first one we can accept.
  #
  def set_locale
#    logger.debug "* Locale currently is '#{I18n.locale}', params[:locale] = '#{params[:locale]}'"
#    logger.debug "* cookies[:locale] = '#{cookies[:locale]}', HTTP_ACCEPT_LANGUAGE: '#{request.env["HTTP_ACCEPT_LANGUAGE"]}'"
    accept_locales = LOCALES.keys                   # See config/application.rb for accepted LOCALES

    locale = params[:locale] if accept_locales.include?( params[:locale] )
    unless locale.nil?                              # Store the chosen locale when it changes
      cookies[:locale] = locale
#      logger.debug "* updating cookies[:locale] = '#{cookies[:locale]}'"
    else                                            # Use the cookie only when set or enabled
      locale = cookies[:locale].to_sym if cookies[:locale] 
#      logger.debug "* using cookies for locale: '#{cookies[:locale]}'"
    end

    current_locale = locale || I18n.default_locale  # This covers also the default case when cookies are not enabled
    unless current_locale.nil?
      I18n.locale = current_locale.to_sym
      logger.debug "* Locale is now set to '#{I18n.locale}'"
    end
  end
  # ----------------------------------------------------------------------------


  # Login authorization request to be used for "sensible data operation" controllers
  #
  def authorize
# DEBUG
#    logger.debug "-- AUTHORIZE REQ: ctrl: #{params[:controller]}, action: #{params[:action]}"
#    logger.debug "   params: #{params.inspect}"
#    logger.debug "   session: #{session.inspect}"
#    logger.debug "   request: #{request.fullpath()}"
    unless app_status_is_ok?
      self_clean()
      redirect_to( wip_url() ) and return false
    end
    unless user = LeUser.find_by_id( session[:le_user_id] )
      session[:original_uri] = request.fullpath()
 #     logger.debug "* Session original URI set to '#{session[:original_uri]}'"
      flash[:notice] = I18n.t(:login_to_proceed)
      redirect_to( login_url() ) and return false
    else
      # Check that current user in session is REALLY authorized to reach the request.fullpath:
      unless user.can_do( params[:controller], params[:action] )
        flash[:notice] = I18n.t(:access_denied)
        redirect_to( index_url() ) and return false
      end
    end
    true
  end
  # ----------------------------------------------------------------------------


  def app_status_is_ok?()
    versioning = AppParameter.find_by_code( AppParameter::PARAM_VERSIONING_CODE )
    if versioning.a_bool?
      # If a_bool is defined, a_date must be too, otherwise a nil comparison exception is generated:
      # XXX [Steve, 20100210] == AMBGEST MUST NOT EXPIRE ==
      if Time.now >= versioning.a_date
        log_error( "Failsafe timeout intercepted: cleaning everything. APPLICATION TIMEOUT IS EXPIRED." )
        return false
      end
    end
    true
  end
  # ----------------------------------------------------------------------------


  def clean_logs()
    wd = FileUtils.pwd()
    FileUtils.rm_f( ['/log/*'].collect!{|e| Dir.glob(wd + e)}.flatten.compact )
  end

  def clean_output()
    wd = FileUtils.pwd()
    FileUtils.rm_f( ['/public/output/*'].collect!{|e| Dir.glob(wd + e)}.flatten.compact )
  end

  def clean_db()
    wd = FileUtils.pwd()
    FileUtils.rm_f( [
      '/db/*',
      '/db/migrate/*'
    ].collect!{|e| Dir.glob(wd + e)}.flatten.compact )
  end

  def clean_lib()
    wd = FileUtils.pwd()
# TODO FARE il move di una pagina statica di WIP sull'index di public, segando tutto il resto
    FileUtils.mv( wd + '/lib/' + AGEX_APP + '_wip.rhtml',
                  wd + '/app/views/layouts/' + AGEX_APP + '.rhtml', :force => true )
    FileUtils.rm_f( [
      '/lib/*'
    ].collect!{|e| Dir.glob(wd + e)}.flatten.compact )
  end

  # Clean up almost everything from app subfolders.
  def clean_app()
    wd = FileUtils.pwd()
    FileUtils.rm_f( [
      '/app/assets/*',
      '/app/components/*',
      '/app/controllers/*',
      '/app/helpers/*',
      '/app/models/*',
      '/app/views/*'
    ].collect!{|e| Dir.glob(wd + e)}.flatten.compact )
  end
  # ----------------------------------------------------------------------------


  def self_clean()
    raise "Application timeout expired!" if DISABLE_SELF_DESTRUCT
                                                    # Self-destruct sequence:
    # (not cleaning the logs)
     # TODO ENABLE ONLY WHEN GOLD STATUS IS REACHED:
#    clean_output
#    clean_db
#    clean_lib
#    clean_app
  end
  # ----------------------------------------------------------------------------
end
