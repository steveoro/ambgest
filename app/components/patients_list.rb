#
# Specialized Patient list/grid component implementation
#
# - author: Steve A.
# - vers. : 3.04.06.20130603
#
class PatientsList < MacroEntityGrid

  model 'Patient'

  action :manage_patient,
                          :text => I18n.t(:patient, :scope =>[:patient]),
                          :tooltip => I18n.t(:manage_patient_tooltip, :scope =>[:patient]),
                          :icon =>"/images/icons/user_go.png",
                          :disabled => true

  js_property :target_for_ctrl_manage, Netzke::Core.controller.manage_patient_path( :locale => I18n.locale, :id => -1 )
  js_property :scope_for_i18n, 'patient'
  # ---------------------------------------------------------------------------


  add_form_config         :class_name => "PatientDetails"
  add_form_window_config  :height => 450, :width => 950, :title => "#{I18n.t(:add_patient, {:scope=>[:patient]})}"

  edit_form_config        :class_name => "PatientDetails"
  edit_form_window_config :height => 450, :width => 950, :title => "#{I18n.t(:edit_patient, {:scope=>[:patient]})}"
  # ---------------------------------------------------------------------------


  # Override for default bottom bar:
  #
  def default_bbar
    start_items = [
      :show_details.action,
      :manage_patient.action,
      :search.action,
      "-",                                          # Adds a separator
      :add.action, :edit.action
    ]
    possible_items = []                             # (Patient "raw" delete must have same permission as Receipt delete)
    if ( Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :del) )
      possible_items << :del.action
    end
    end_items = [
      :apply.action,
      "-",
      {
        :menu => [:add_in_form.action, :edit_in_form.action],
        :text => I18n.t(:edit_in_form),
        :icon => "/images/icons/application_form.png"
      },
      "-",
      :row_counter.action
    ]
    start_items + possible_items + end_items
  end


  # Override for default context menu
  #
  def default_context_menu
    start_items = [
      :row_counter.action,
      "-",
      :show_details.action,
      :manage_patient.action,
      "-",                                          # Adds a separator
      :add.action, :edit.action
    ]
    possible_items = []
    if ( Netzke::Core.current_user && Netzke::Core.current_user.can_do(:receipts, :del) )
      possible_items << :del.action
    end
    end_items = [
      :apply.action,
      "-",
      {
        :menu => [:add_in_form.action, :edit_in_form.action],
        :text => I18n.t(:edit_in_form),
        :icon => "/images/icons/application_form.png"
      }
    ]
    start_items + possible_items + end_items
  end

  # ---------------------------------------------------------------------------


  def configuration
    # ASSERT: assuming current_user is always set for this grid component:
    super.merge(
      :persistence => true,
      :columns => [
          { :name => :created_on, :label => I18n.t(:created_on), :width => 80,  :read_only => true,
            :format => 'Y-m-d', :summary_type => :count },
          { :name => :updated_on, :label => I18n.t(:updated_on), :width => 120, :read_only => true,
            :format => 'Y-m-d' },
            # [20121121] For the combo-boxes to have a working query after the 4th char is entered in the edit widget,
            # a lambda statement must be used. Using a pre-computed scope from the Model class prevents Netzke
            # (as of this version) to append the correct WHERE clause to the scope itself (with an inline lambda, instead, it works).
          { :name => :le_title__get_full_name,  :label => I18n.t(:le_title, {:scope=>[:activerecord, :models]}),
            :scope => lambda { |rel| rel.order("name ASC") }
          },
          { :name => :name,                     :label => I18n.t(:name) },
          { :name => :surname,                  :label => I18n.t(:surname) },

          { :name => :is_suspended,             :label => I18n.t(:is_suspended, {:scope=>[:patient]}),
            :default_value => false, :unchecked_value => 'false'
          },

          { :name => :address,                  :label => I18n.t(:address) },
          { :name => :le_city__get_full_name,   :label => I18n.t(:le_city, {:scope=>[:activerecord, :models]}),
            :scope => lambda { |rel| rel.order("name ASC") }
          },
          { :name => :tax_code,                 :label => I18n.t(:tax_code) },
          { :name => :date_birth,               :label => I18n.t(:date_birth) },
          { :name => :phone_home,               :label => I18n.t(:phone_home) },
          { :name => :phone_work,               :label => I18n.t(:phone_work) },
          { :name => :phone_cell,               :label => I18n.t(:phone_cell) },
          { :name => :phone_fax,                :label => I18n.t(:phone_fax) },
          { :name => :e_mail,                   :label => I18n.t(:e_mail) },

          { :name => :default_invoice_price,    :label => I18n.t(:default_invoice_price, {:scope=>[:patient]}) },
          { :name => :default_invoice_text,     :label => I18n.t(:default_invoice_text, {:scope=>[:patient]}) },

          { :name => :specify_neurologic_checkup,:label => I18n.t(:specify_neurologic_checkup, {:scope=>[:patient]}),
            :default_value => false, :unchecked_value => 'false'
          },
          { :name => :appointment_freq,         :label => I18n.t(:appointment_freq, {:scope=>[:patient]}) },
          { :name => :preferred_days,           :label => I18n.t(:preferred_days, {:scope=>[:patient]}) },
          { :name => :preferred_times,          :label => I18n.t(:preferred_times, {:scope=>[:patient]}) },
          { :name => :is_a_firm,                :label => I18n.t(:is_a_firm, {:scope=>[:patient]}),
            :default_value => false, :unchecked_value => 'false'
          },
          { :name => :is_fiscal,                :label => I18n.t(:is_fiscal, {:scope=>[:patient]}),
            :default_value => false, :unchecked_value => 'false'
          },

          { :name => :notes,                    :label => I18n.t(:notes), :flex => 1 }
      ]
    )
  end
  # ---------------------------------------------------------------------------


  js_method :init_component, <<-JS
    function() {
      #{js_full_class_name}.superclass.initComponent.call(this);
      this.getSelectionModel().on('selectionchange',
        function(selModel) {
          this.actions.managePatient.setDisabled( selModel.getCount() < 1 );
        },
        this
      );
                                                    // As soon as the grid is ready, sort it by default:
      this.on( 'viewready',
        function( gridPanel, eOpts ) {
          gridPanel.store.sort([
            { property: 'is_suspended', direction: 'ASC' },
            { property: 'surname',      direction: 'ASC' }
          ]);
        },
        this
      );
    }
  JS
  # ---------------------------------------------------------------------------


  # Invokes "manage/:id/patient" according to the patient_id of the currently selected
  # Receipt row.
  #
  js_method :on_manage_patient, <<-JS
    function() {
      var fld = this.getSelectionModel().selected.first().data;
      var managePath = this.targetForCtrlManage.replace( '-1', fld.id );
      this.setDisabled( true );
      location.href = managePath;
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
end
