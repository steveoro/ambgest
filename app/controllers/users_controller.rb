class UsersController < ApplicationController

  # Require authorization before invoking any of this controller's actions:
  before_filter :authorize


  # Default action
  def index
  end


  # Kills a specified session id
  def kill_session
# DEBUG
#    logger.debug "\r\n!! ------ in kill_session -----"
#    logger.debug params
    if params[:id]
      logger.debug "\r\n!! Killing session #{params[:id]}..."
      Session.where( :id => params[:id] ).delete_all
      flash[:notice] = I18n.t(:session_deleted)
    else
      flash[:error] = I18n.t(:unable_to_delete_session)
    end
    redirect_to( whos_online_path() )
  end
  # ---------------------------------------------------------------------------
end
