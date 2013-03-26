#
# Simple Login form, with no ActiveRecord model associated
#
# - author: Steve A.
# - vers. : 0.12.20120203
#
class LoginPanel < Netzke::Basepack::FormPanel

  js_property :body_padding, 5

  js_property :title, I18n.t(:login)

  # We do not need the default apply action (no model associated), so we define a custom action:
  action :perform_login, :text => 'OK', :tooltip => I18n.t(:login_tooltip), :icon => :door_in

  js_property :bbar, [ :perform_login.action ]


  # Override default configuration for bottom bar
  # (this level of override is required only if base class is a FormPanel, otherwise the js_property suffices enough)
  def configure_bbar( config )
    config[:bbar] = [ :perform_login.action ]
  end


  items [
    {
      :xtype => :fieldcontainer, :layout => :vbox, :label_width => 125,
      :height => 60, :width => 250,
      :field_defaults => {
        :xtype => :textfield, :margin => '4 2 2 2', :height => 18, :allow_blank => false
      },
      :items => [
        { :name => :user_name,  :field_label => I18n.t(:user), :empty_text => "(#{I18n.t(:user)})",
          :width => 180
        },
        { :name => :password,   :field_label => I18n.t(:password), :empty_text => "(#{I18n.t(:password)})",
          :width => 200,        :input_type => :password, :allow_blank => false
        }
      ]
    }
  ]

  # ---------------------------------------------------------------------------


  js_method :init_component, <<-JS
    function(){
      #{js_full_class_name}.superclass.initComponent.call(this);

      Ext.FocusManager.enable();
      var nav = Ext.create('Ext.util.KeyNav', Ext.getBody(), {
          "enter" : function(){
              this.onPerformLogin();
          },
          "up" : function() {
              var el = Ext.FocusManager.focusedCmp;
              if (el.up()) el.up().focus();
          },
          "down" : function() {
              var el = Ext.FocusManager.focusedCmp;
              if (el.items) el.items.items[0].focus();
          },
          scope : this
      });
    }  
  JS

  # ---------------------------------------------------------------------------


  js_method :on_perform_login, <<-JS
    function() {
      var flds = this.getForm().getFields().items;
      var u = flds[0].getValue();
      var p = flds[1].getValue();
      this.performLogin( {user:u, password:p} );
    }
  JS


  js_method :redirect_to_uri, <<-JS
    function( uri ) {
      if ( uri != '' )
        location.href = uri;
    }
  JS


  # Called by pressing the OK button
  endpoint :perform_login do |params|
#    logger.debug "\r\n!! ------ in :perform_login (endpoint) -----"
#    logger.debug params
    le_user = LeUser.authenticate( params[:user], params[:password] )

    if le_user
      session[:le_user_id] = le_user.id
#      logger.debug "!! original URI: '#{session[:original_uri]}'"
#      logger.debug "!! current_user: #{Netzke::Core.current_user}"
#      logger.debug "!! index_path:   '#{Netzke::Core.controller.index_path()}'"
      uri = nil                                     # Initialize result URI
      uri = session[:original_uri] if (session[:original_uri] != '') && (! session[:original_uri].nil?)
      uri = Netzke::Core.controller.index_path() if (uri.nil? || uri.empty?)
#      logger.debug "!! result URI:   '#{uri}'"
      session[:original_uri] = nil                  # Clear original session URI
      Netzke::Core.login()                          # Set the login for Netzke
      flash :notice => "#{I18n.t(:hi)} #{le_user.description} !"
      { :redirect_to_uri => uri }                   # return result is required for success
    else
      Netzke::Core.controller.reset_session
      Netzke::Core.logout()
      # flash errors
      err_msg = I18n.t(:invalid_user)
      flash :error => err_msg
      # Checkout Netzke::Basepack::FormPanel::Services for more details:
      { :netzke_feedback => @flash, :apply_form_errors => {:user => [err_msg]} }
    end
  end

end