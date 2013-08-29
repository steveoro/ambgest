# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|
  # Specify a custom renderer if needed.
  # The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
  # The renderer can also be specified as option in the render_navigation call.
  # navigation.renderer = Your::Custom::Renderer

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  # navigation.selected_class = 'your_selected_class'

  # Specify the class that will be applied to the current leaf of
  # active navigation items. Defaults to 'simple-navigation-active-leaf'
  # navigation.active_leaf_class = 'your_active_leaf_class'

  # Item keys are normally added to list items as id.
  # This setting turns that off
  # navigation.autogenerate_item_ids = false

  # You can override the default logic that is used to autogenerate the item ids.
  # To do this, define a Proc which takes the key of the current item as argument.
  # The example below would add a prefix to each key.
  # navigation.id_generator = Proc.new {|key| "my-prefix-#{key}"}

  # If you need to add custom html around item names, you can define a proc that will be called with the name you pass in to the navigation.
  # The example below shows how to wrap items spans.
  # navigation.name_generator = Proc.new {|name| "<span>#{name}</span>"}

  # The auto highlight feature is turned on by default.
  # This turns it off globally (for the whole plugin)
  # navigation.auto_highlight = false

  # Define the primary navigation
  navigation.items do |primary|
    # Add an item to the primary navigation. The following params apply:
    # key - a symbol which uniquely defines your navigation item in the scope of the primary_navigation
    # name - will be displayed in the rendered navigation. This can also be a call to your I18n-framework.
    # url - the address that the generated item links to. You can also use url_helpers (named routes, restful routes helper, url_for etc.)
    # options - can be used to specify attributes that will be included in the rendered navigation item (e.g. id, class etc.)
    #           some special options that can be set:
    #           :if - Specifies a proc to call to determine if the item should
    #                 be rendered (e.g. <tt>:if => Proc.new { current_user.admin? }</tt>). The
    #                 proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :unless - Specifies a proc to call to determine if the item should not
    #                     be rendered (e.g. <tt>:unless => Proc.new { current_user.admin? }</tt>). The
    #                     proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :method - Specifies the http-method for the generated link - default is :get.
    #           :highlights_on - if autohighlighting is turned off and/or you want to explicitly specify
    #                            when the item should be highlighted, you can set a regexp which is matched
    #                            against the current URI.  You may also use a proc, or the symbol <tt>:subpath</tt>. 
    #
    primary.dom_class = 'nav'

    primary.item :key_main, t('agex_action.main') do |sub_nav|
      sub_nav.item :key_index,              t('agex_action.home'),  index_path()
      sub_nav.item :key_about,              t('agex_action.about'), about_path()
      sub_nav.item :key_contact_us,         t('agex_action.contact_us'), contact_us_path()
      sub_nav.item :key_separator1,         '<hr>', '#', :class => 'disabled'
      sub_nav.item( :key_edit_current_user,
        t('agex_action.edit_current_user'), edit_current_user_path(),
        :class => ( Netzke::Core.current_user ? Netzke::Core.current_user.get_css_class_to_do( :welcome, :edit_current_user ) : nil ),
        :unless => Proc.new { Netzke::Core.current_user.nil? }
      )
      sub_nav.item :key_separator2,         '<hr>', '#', :class => 'disabled', :unless => Proc.new { Netzke::Core.current_user.nil? }
      sub_nav.item :key_login,              t('agex_action.login'), login_path(), :if => Proc.new { Netzke::Core.current_user.nil? }
      sub_nav.item :key_logout,             t('agex_action.logout'), logout_path(), :unless => Proc.new { Netzke::Core.current_user.nil? }
    end

    primary.item( :key_patients_and_appointments,
      t('agex_action.patients_and_appointments'), '#',
      :if => Proc.new { Netzke::Core.current_user ? Netzke::Core.current_user.can_access( :patients ) : false }
    ) do |sub_nav|
      sub_nav.item( :key_patients,
        t('agex_action.patients'),  patients_path(),
        :class => ( Netzke::Core.current_user ? Netzke::Core.current_user.get_css_class_to_access( :patients ) : nil )
      )
      sub_nav.item :key_separator3, '<hr>', '#', :class => 'disabled'
      sub_nav.item( :key_appointments,
        t('agex_action.appointments'), appointments_path(),
        :class => ( Netzke::Core.current_user ? Netzke::Core.current_user.get_css_class_to_access( :appointments ) : nil )
      )
    end

    primary.item( :key_week_plan_and_schedules,
      t('agex_action.week_plan'), '#',
      :if => Proc.new { Netzke::Core.current_user ? Netzke::Core.current_user.can_access( :week_plan ) : false }
    ) do |sub_nav|
      sub_nav.item( :key_week_plan,
        t('agex_action.week_plan'),  week_plan_path(),
        :class => ( Netzke::Core.current_user ? Netzke::Core.current_user.get_css_class_to_access( :week_plan ) : nil )
      )
      sub_nav.item :key_separator4, '<hr>', '#', :class => 'disabled'
      sub_nav.item( :key_schedules,
        t('agex_action.schedules'), schedules_path(),
        :class => ( Netzke::Core.current_user ? Netzke::Core.current_user.get_css_class_to_access( :schedules ) : nil )
      )
    end

    primary.item( :key_receipts,
      t('agex_action.receipts'), receipts_path(),
      :if => Proc.new { Netzke::Core.current_user ? Netzke::Core.current_user.can_access( :receipts ) : false }
    )
    primary.item( :key_setup,
      t('agex_action.sub_entities'), setup_path(),
      :if => Proc.new { Netzke::Core.current_user ? Netzke::Core.current_user.can_access( :setup ) : false }
    )

    primary.item( :key_manage_system,
      t('agex_action.manage_system'), '#',
      :if => Proc.new { Netzke::Core.current_user ? Netzke::Core.current_user.can_access( :articles ) : false }
    ) do |sub_nav|
      sub_nav.item( :key_articles,
        t('agex_action.articles'),  articles_path(),
        :class => ( Netzke::Core.current_user ? Netzke::Core.current_user.get_css_class_to_access( :articles ) : nil )
      )
      sub_nav.item( :key_whos_online,
        t('agex_action.whos_online'), whos_online_path(),
        :class => ( Netzke::Core.current_user ? Netzke::Core.current_user.get_css_class_to_do( :welcome, :whos_online ) : nil )
      )
      sub_nav.item :key_separator5, '<hr>', '#', :class => 'disabled'
      sub_nav.item( :key_users,
        t('agex_action.users'), users_path(),
        :class => ( Netzke::Core.current_user ? Netzke::Core.current_user.get_css_class_to_access( :users ) : nil )
      )
      sub_nav.item( :key_app_parameters,
        t('agex_action.app_parameters'), app_parameters_path(),
        :class => ( Netzke::Core.current_user ? Netzke::Core.current_user.get_css_class_to_access( :app_parameters ) : nil )
      )
    end

    # you can also specify a css id or class to attach to this particular level
    # works for all levels of the menu
    # primary.dom_id = 'menu-id'
    # primary.dom_class = 'menu-class'

    # You can turn off auto highlighting for a specific level
    # primary.auto_highlight = false

  end

end
