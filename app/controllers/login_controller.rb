class LoginController < ApplicationController

  # Add :add_user to except clause of before_filter below when user base is empty
  # and the correct add_user action in setup_controller cannot yet be accessed.
  before_filter :authorize, :except => [:login, :logout]


  # Login: just displays the form and wait for user to
  # enter a name and password
  def login
  end


  def logout
    reset_session                                   # While logging out, clean up also all idle sessions older than an hour:
    Session.destroy_all( '(now() - updated_on > 3600)' )
    clean_old_output()
    flash[:notice] = I18n.t(:disconnected)
    redirect_to( login_path() )
  end
end
