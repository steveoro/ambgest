#
# Specialized User list/grid component implementation
#
# - author: Steve A.
# - vers. : 0.29.20121114 (AmbGest3 version)
#
class UsersList < EntityGrid

  model 'LeUser'

  js_properties(
    :prevent_header => true,
    :header => false,
    :border => true
  )

  add_form_config :class_name => "UserDetails"
  add_form_window_config :width => 500, :title => "#{I18n.t(:add)} #{I18n.t(:user)}"

  edit_form_config :class_name => "UserDetails"
  edit_form_window_config :width => 500, :title => "#{I18n.t(:edit)} #{I18n.t(:user)}"
  # ---------------------------------------------------------------------------


  # Override for bottom bar:
  #
 def default_bbar
  [
     :show_details.action,                          # The custom action defined below via JS
     :search.action,
     "-",                                           # Adds a separator
     :del.action,
     "-",
     {
        :menu => [:add_in_form.action, :edit_in_form.action],
        :text => I18n.t(:edit_in_form),
        :icon => "/images/icons/application_form.png"
     },
     "-",
     :row_counter.action
  ]
 end


  # Override for context menu
  #
  def default_context_menu
    [
       :row_counter.action,
       "-",                                         # Adds a separator
       :show_details.action,                        # The custom action defined below via JS
       "-",                                         # Adds a separator
       :del.action,
       "-",                                         # Adds a separator
       :add_in_form.action,
       :edit_in_form.action
    ]
  end
  # ---------------------------------------------------------------------------


  def configuration
    # ASSERT: assuming current_user is always set for this grid component:
    super.merge(
      :persistence => true,
      :strong_default_attrs => {
        :user_id => Netzke::Core.current_user.id
      },

      :columns => [
          { :name => :created_on, :label => I18n.t(:created_at), :width => 80, :read_only => true,
            :format => 'Y-m-d', :summary_type => :count },
          { :name => :updated_on, :label => I18n.t(:updated_at), :width => 120, :read_only => true,
            :format => 'Y-m-d' },
          { :name => :name, :label => I18n.t(:name) },
          { :name => :description, :label => I18n.t(:description), :flex => 1 },

          { :name => :authorization_level,  :label => I18n.t(:authorization_level),
            :min_value => 1, :max_value => ( Netzke::Core.current_user ? Netzke::Core.current_user.authorization_level : 1),
            :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :users )) : true }
      ]
    )
  end
  # ---------------------------------------------------------------------------
end
