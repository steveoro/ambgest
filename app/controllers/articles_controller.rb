class ArticlesController < ApplicationController

  # Require authorization before invoking any of this controller's actions:
  before_filter :authorize


  # Default action
  def index
    ap = AppParameter.get_parameter_row_for( :articles )
    @max_view_height = ap.get_view_height()
    @context_title = I18n.t(:articles_list)
  end
  # ---------------------------------------------------------------------------

end
