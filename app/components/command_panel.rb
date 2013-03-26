#
# == Main Command Panel / Menu Toolbar component implementation
#
# - author: Steve A.
# - vers. : 0.25.20121121 (AmbGest3 version)
#
require 'netzke/core'


class CommandPanel < Netzke::Basepack::Panel

  action :patients,
    :text => I18n.t(:patients, :scope =>[:agex_action]),
    :tooltip => I18n.t(:patients_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/group.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :patients )) : true

  action :appointments,
    :text => I18n.t(:appointments, :scope =>[:agex_action]),
    :tooltip => I18n.t(:appointments_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/date.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :appointments )) : true

  action :week_plan,
    :text => I18n.t(:week_plan, :scope =>[:agex_action]),
    :tooltip => I18n.t(:week_plan_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/calendar.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :week_plan )) : true

  action :schedules,
    :text => I18n.t(:schedules, :scope =>[:agex_action]),
    :tooltip => I18n.t(:schedules_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/note_go.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :schedules )) : true

  action :receipts,
    :text => I18n.t(:receipts, :scope =>[:agex_action]),
    :tooltip => I18n.t(:receipts_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/database_table.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :receipts )) : true

  action :articles,
    :text => I18n.t(:articles, :scope =>[:agex_action]),
    :tooltip => I18n.t(:articles_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/user_comment.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :articles )) : true

  action :users,
    :text => I18n.t(:users, :scope =>[:agex_action]),
    :tooltip => I18n.t(:users_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/user_suit.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :users )) : true

  action :app_parameters,
    :text => I18n.t(:app_parameters, :scope =>[:agex_action]),
    :tooltip => I18n.t(:app_parameters_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/wrench_orange.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :app_parameters )) : true

  action :setup,
    :text => I18n.t(:sub_entities, :scope =>[:agex_action]),
    :tooltip => I18n.t(:sub_entities_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/table_relationship.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :setup )) : true

  action :index,
    :text => I18n.t(:home, :scope =>[:agex_action]),
    :tooltip => I18n.t(:home_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/house_go.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :welcome )) : true

  action :about,
    :text => I18n.t(:about, :scope =>[:agex_action]),
    :tooltip => I18n.t(:about_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/information.png"

  action :contact_us,
    :text => I18n.t(:contact_us, :scope =>[:agex_action]),
    :tooltip => I18n.t(:contact_us_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/email.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :welcome )) : true

  action :whos_online,
    :text => I18n.t(:whos_online, :scope =>[:agex_action]),
    :tooltip => I18n.t(:whos_online_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/monitor.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_do( :welcome, :whos_online )) : true

  action :edit_current_user,
    :text => I18n.t(:edit_current_user, :scope =>[:agex_action]),
    :tooltip => I18n.t(:edit_current_user_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/user_edit.png",
    :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_do( :welcome, :edit_current_user )) : true

  action :logout,
    :text => I18n.t(:logout, :scope =>[:agex_action]),
    :tooltip => I18n.t(:logout_tooltip, :scope =>[:agex_action]),
    :icon =>"/images/icons/door_out.png"
  # ---------------------------------------------------------------------------


  js_property :tbar, [
    {
      :menu => [
        :index.action,
        :about.action,
        :contact_us.action,
        "-",
        :edit_current_user.action,
        "-",
        :logout.action
      ],
      :text => I18n.t(:main, :scope =>[:agex_action]),
      :icon => "/images/icons/application_home.png"
    },
    {
      :menu => [ :patients.action, "-", :appointments.action ],
      :text => I18n.t(:patients_and_appointments, :scope =>[:agex_action]),
      :icon => "/images/icons/group.png",
      :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :patients )) : true
    },
    {
      :menu => [ :week_plan.action, :schedules.action ],
      :text => I18n.t(:week_plan, :scope =>[:agex_action]),
      :icon => "/images/icons/calendar.png",
      :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :week_plan )) : true
    },
    {
      :menu => [ :receipts.action ],
      :text => I18n.t(:receipts, :scope =>[:agex_action]),
      :icon => "/images/icons/folder_table.png",
      :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :receipts )) : true
    },
    {
      :menu => [ :setup.action ],
      :text => I18n.t(:sub_entities, :scope =>[:agex_action]),
      :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :setup )) : true
    },
    {
      :menu => [ :articles.action, :whos_online.action, "-", :users.action, :app_parameters.action ],
      :text => I18n.t(:manage_system, :scope =>[:agex_action]),
      :icon => "/images/icons/computer.png",
      :disabled => Netzke::Core.current_user ? (! Netzke::Core.current_user.can_access( :articles )) : true
    }
  ]



  js_properties(
    :prevent_header => true,
    :header => false
  )


  def configuration
    super.merge(
      :min_height => 28,
      :height => 28,
      :margin => 0
    )
  end
  # ---------------------------------------------------------------------------


  js_method :init_component, <<-JS
    function(){
      #{js_full_class_name}.superclass.initComponent.call(this);
    }  
  JS
  # ---------------------------------------------------------------------------


  # Front-end JS event handler for the action 'patients' (index)
  #
  js_method :on_patients, <<-JS
    function(){
      location.href = "#{LeUser.new.patients_path()}";
    }
  JS

  # Front-end JS event handler for the action 'appointments' (index)
  #
  js_method :on_appointments, <<-JS
    function(){
      location.href = "#{LeUser.new.appointments_path()}";
    }
  JS

  # Front-end JS event handler for the action 'week_plan' (index)
  #
  js_method :on_week_plan, <<-JS
    function(){
      location.href = "#{LeUser.new.week_plan_path()}";
    }
  JS

  # Front-end JS event handler for the action 'schedules' (index)
  #
  js_method :on_schedules, <<-JS
    function(){
      location.href = "#{LeUser.new.schedules_path()}";
    }
  JS

  # Front-end JS event handler for the action 'receipts' (index)
  #
  js_method :on_receipts, <<-JS
    function(){
      location.href = "#{LeUser.new.receipts_path()}";
    }
  JS
  # ---------------------------------------------------------------------------


  # Front-end JS event handler for the action 'articles' (index)
  #
  js_method :on_articles, <<-JS
    function(){
      location.href = "#{LeUser.new.articles_path()}";
    }
  JS

  # Front-end JS event handler for the action 'users' (index)
  #
  js_method :on_users, <<-JS
    function(){
      location.href = "#{LeUser.new.users_path()}";
    }
  JS

  # Front-end JS event handler for the action 'users' (index)
  #
  js_method :on_app_parameters, <<-JS
    function(){
      location.href = "#{LeUser.new.app_parameters_path()}";
    }
  JS
  # ---------------------------------------------------------------------------

  # Front-end JS event handler for the action 'index' (welcome/index)
  #
  js_method :on_index, <<-JS
    function(){
      location.href = "#{LeUser.new.index_path()}";
    }
  JS

  # Front-end JS event handler for the action 'about' (welcome/about)
  #
  js_method :on_about, <<-JS
    function(){
      location.href = "#{LeUser.new.about_path()}";
    }
  JS

  # Front-end JS event handler for the action 'contact_us' (welcome/contact_us)
  #
  js_method :on_contact_us, <<-JS
    function(){
      location.href = "#{LeUser.new.contact_us_path()}";
    }
  JS

  # Front-end JS event handler for the action 'whos_online' (welcome/whos_online)
  #
  js_method :on_whos_online, <<-JS
    function(){
      location.href = "#{LeUser.new.whos_online_path()}";
    }
  JS

  # Front-end JS event handler for the action 'edit_current_user' (welcome/edit_current_user)
  #
  js_method :on_edit_current_user, <<-JS
    function(){
      location.href = "#{LeUser.new.edit_current_user_path()}";
    }
  JS
  # ---------------------------------------------------------------------------

  # Front-end JS event handler for the action 'setup' (setup)
  #
  js_method :on_setup, <<-JS
    function(){
      location.href = "#{LeUser.new.setup_path()}";
    }
  JS
  # ---------------------------------------------------------------------------

  # Front-end JS event handler for the action 'logout' (login)
  #
  js_method :on_logout, <<-JS
    function(){
      location.href = "#{LeUser.new.logout_path()}";
    }
  JS
  # ---------------------------------------------------------------------------
end
