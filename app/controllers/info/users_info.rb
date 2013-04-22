# Contains "Info" retrieval methods to be shared between different controllers.
# To be able to use these methods, simply include this module into the desired
# Controller class.
#
module Info::UsersInfo
  protected


  # Retrieves the list of all logged-in users reading currently stored sessions
  # returning an array of user names.
  # == Return:
  # An hash in the form: { session_id => user_name, ... }
  #
  # == Parameters:
  #
  # +include_description+::
  #   when +true+, each resulting item string will have its long user description appended into 
  #
  def self.retrieve_online_users( include_description = false )
    all_sessions = ActiveRecord::SessionStore::Session.find( :all )
    result_hash = {}

    all_sessions.each do |one_session|
# DEBUG
#      logger.debug("\r\n--- Session.data..............: #{one_session.data.inspect}")
#      logger.debug("--- Session.data['le_user_id']: #{one_session.data['le_user_id'].inspect}")
#      logger.debug("--- Session...................: #{one_session.inspect}")
      if ( one_session.data['le_user_id'] )
        user = LeUser.find_by_id( one_session.data['le_user_id'] )
        if user
          result_hash[ one_session.id ] = include_description ? "#{user.name}" : "#{user.get_full_name}"
        else
          logger.debug("\r\n[W] - Unable to find user data in session!")
          logger.debug("Session data: #{one_session.data.inspect}")
        end
      end
    end
    result_hash
  end
  # ---------------------------------------------------------------------------
end
