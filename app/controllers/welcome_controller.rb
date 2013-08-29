class WelcomeController < ApplicationController
  include Info::UsersInfo

  require 'common/format'

  # Require authorization before invoking any of this controller's actions:
  before_filter :authorize, :except => [ :about, :contact_us, :wip ]


  def index
    @articles = Article.find(
      :all,
      :order => "is_sticky DESC, updated_on DESC",
      :limit => AppParameter.get_default_pagination_rows_for( :articles )
    )
    @context_title = I18n.t(:welcome)
  end
  # ----------------------------------------------------------------------------
  #++

  def about
    @versioning = AppParameter.find_by_code( AppParameter::PARAM_VERSIONING_CODE )
    @default_firm_logo = AppParameter.get_default_firm_logo_big( @versioning.get_default_firm_id )
                                                    # Retrieve, cleanse and pre-format gem info:
    @gem_info = []
    %x{gem list -l --no-details}.split("\n").each{ |row|
      @gem_info << row if row =~ / \([0-9]/
    }
    @context_title = I18n.t(:about)
  end


  def contact_us
    @context_title = I18n.t(:contact_us)
  end


  # Action used to allow the current user to edit its profile 
  def edit_current_user
    @context_title = "#{I18n.t(:user)} '#{Netzke::Core.current_user.name}'"
  end


  # "Who's online" command
  #
  def whos_online
    @online_users = Info::UsersInfo.retrieve_online_users( true ) # (retrieve also full description)
    @context_title = I18n.t(:whos_online, :scope => [:agex_action])
  end


  # "Work In Progress" indicator
  def wip
    @context_title = 'WIP'
  end
  # ----------------------------------------------------------------------------
  #++
end
