class AppParametersController < ApplicationController

  # Require authorization before invoking any of this controller's actions:
  before_filter :authorize


  # Default action
  def index
    @context_title = I18n.t(:app_parameters, {:scope=>[:agex_action]})
  end
  # ---------------------------------------------------------------------------
end
