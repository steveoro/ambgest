#
# Specialized Article list/grid component implementation
#
# - author: Steve A.
# - vers. : 3.05.05.20131002
#
class ArticlesList < EntityGrid

  model 'Article'
  # ---------------------------------------------------------------------------


  def configuration
    super.merge(
      :prevent_header => true,
      :enable_pagination => ( toggle_pagination = AppParameter.get_default_pagination_enable_for( :articles ) ),
      # [Steve, 20120914] It seems that the LIMIT parameter used during column sort can't be toggled off even when pagination is false, so we put an arbitrary 10Tera row count limit per page to get all the rows: 
      :rows_per_page => ( toggle_pagination ? AppParameter.get_default_pagination_rows_for( :articles ) : 1000000000000 ),

      :add_form_window_config => { :width => 650, :title => "#{I18n.t(:add)} #{I18n.t(:article, {:scope=>[:activerecord, :models]})}" },
      :edit_form_window_config => { :width => 650, :title => "#{I18n.t(:edit)} #{I18n.t(:article, {:scope=>[:activerecord, :models]})}" },

      :columns => [
        { :name => :created_on, :label => I18n.t(:created_on), :width => 80, :read_only => true,
          :format => 'Y-m-d', :summary_type => :count },
        { :name => :updated_on, :label => I18n.t(:updated_on), :width => 80, :read_only => true,
          :format => 'Y-m-d' },
        { :name => :title, :label => I18n.t(:title) },
        { :name => :entry_text, :label => I18n.t(:entry_text), :flex => 1 },
        { :name => :le_user__name, :label => I18n.t(:user), :width => 70, :sorting_scope => :sort_article_by_user,
          :default_value => Netzke::Core.current_user.id },
        { :name => :is_sticky, :label => I18n.t(:is_sticky),
          :default_value => false, :unchecked_value => 'false'
        }
      ]
    )
  end


  js_method :init_component, <<-JS
    function(){
      // Another - more convolute way - to call superclass's initComponent:
      #{js_full_class_name}.superclass.initComponent.call(this);
                                                    // As soon as the grid is ready, sort it by default:
      this.on( 'viewready',
        function( gridPanel, eOpts ) {
          gridPanel.store.sort([ { property: 'updated_on', direction: 'DESC' } ]);
        },
        this
      );
    }  
  JS
  # ---------------------------------------------------------------------------


  # Override default fields for forms. Must return an array understood by the
  # items property of the forms.
  #
  def default_fields_for_forms
    [
      { :name => :created_on, :field_label => I18n.t(:created_on), :width => 80, :read_only => true,
        :format => 'Y-m-d', :summary_type => :count },
      { :name => :updated_on, :field_label => I18n.t(:updated_on), :width => 80, :read_only => true,
        :format => 'Y-m-d' },
      { :name => :title, :field_label => I18n.t(:title) },
      { :name => :entry_text, :field_label => I18n.t(:entry_text), :flex => 1 },
      { :name => :le_user__name, :field_label => I18n.t(:user), :width => 70, :sorting_scope => :sort_article_by_user,
        :default_value => Netzke::Core.current_user.id },
      { :name => :is_sticky, :field_label => I18n.t(:is_sticky),
        :default_value => false, :unchecked_value => 'false'
      }
    ]
  end
  # ---------------------------------------------------------------------------
end
