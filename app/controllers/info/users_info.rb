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
      user = LeUser.find_by_id( one_session.data['le_user_id'] ) if one_session.data['le_user_id']
      if user
        result_hash[one_session.id] = include_description ? "#{user.name}" : "#{user.get_full_name}"
      else
        puts("\r\n[W] - Unable to find user data in session!")
        puts("Session data: #{one_session.data.inspect}")
      end
    end
    result_hash
  end
  #-----------------------------------------------------------------------------
  #++
end