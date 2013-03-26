#
# Specialized Schedule rows list/grid component implementation
#
# - author: Steve A.
# - vers. : 0.34.20130215
#
class SchedulesGrid < EntityGrid

  action :manage_patient,
                        :text => I18n.t(:patient, :scope =>[:patient]),
                        :tooltip => I18n.t(:manage_patient_tooltip, :scope =>[:patient]),
                        :icon =>"/images/icons/user_go.png",
                        :disabled => true
  # ---------------------------------------------------------------------------

  # Defines a dummy target for the "patient manage" action
  #
  js_property :target_for_patient_manage, Netzke::Core.controller.manage_patient_path( :locale => I18n.locale, :id => -1 )
  # ---------------------------------------------------------------------------


  model 'Schedule'
  js_property :scope_for_i18n, 'schedule'

  js_properties(
    :prevent_header => true,
    :border => false
  )


  add_form_config         :class_name => "ScheduleDetails"
  add_form_window_config  :width => 500, :title => "#{I18n.t(:add_schedule, {:scope=>[:schedule]})}"

  edit_form_config        :class_name => "ScheduleDetails"
  edit_form_window_config :width => 500, :title => "#{I18n.t(:edit_schedule, {:scope=>[:schedule]})}"


  # Override for default bottom bar:
  #
  def default_bbar
    [
      :show_details.action,
      :manage_patient.action,
      :search.action,
      "-",
      :add.action, :edit.action, :del.action,
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
  end


  # Override for default context menu
  #
  def default_context_menu
    [
      :row_counter.action,
      "-",
      :show_details.action,
      :manage_patient.action,
      "-",                                          # Adds a separator
      :add.action, :edit.action, :del.action,
      :apply.action,
      "-",
      {
        :menu => [:add_in_form.action, :edit_in_form.action],
        :text => I18n.t(:edit_in_form),
        :icon => "/images/icons/application_form.png"
      }
    ]
  end

  # ---------------------------------------------------------------------------


  def configuration
    # ASSERT: assuming current_user is always set for this grid component:
    super.merge(
      :persistence => true,
      # [Steve, 20120131]
      # FIXME The Netzke endpoint, once configured, ignores any subsequent request to turn off or resize the pagination
      # TODO Either wait for a new Netzke release that changes this behavior, or rewrite from scratch the endpoint implementation for the service of grid data retrieval
#      :enable_pagination => false,
      # [Steve, 20120914] It seems that the LIMIT parameter used during column sort can't be toggled off, so we put an arbitrary 10Tera row count limit per page to get all the rows: 
#      :rows_per_page => 1000000000000,
      :min_width => 750,

      :columns => [
#        { :name => :created_on, :label => I18n.t(:created_on), :width => 80,   :read_only => true,
#          :format => 'Y-m-d' },
#        { :name => :updated_on, :label => I18n.t(:updated_on), :width => 120,  :read_only => true,
#          :format => 'Y-m-d' },

        { :name => :date_schedule,          :label => I18n.t(:date_schedule, {:scope=>[:schedule]}), :width => 80,
          :format => 'Y-m-d', :default_value => DateTime.now, :width => 160, :summary_type => :count
        },
        { :name => :must_insert,            :label => I18n.t(:must_insert, {:scope=>[:schedule]}),
          :width => 60, :unchecked_value => 'false'
        },
        { :name => :must_move,              :label => I18n.t(:must_move, {:scope=>[:schedule]}),
          :width => 60, :unchecked_value => 'false'
        },
        { :name => :must_call,              :label => I18n.t(:must_call, {:scope=>[:schedule]}),
          :width => 60, :unchecked_value => 'false'
        },
        { :name => :is_done,                :label => I18n.t(:is_done, {:scope=>[:schedule]}),
          :unchecked_value => 'false'
        },

        { :name => :patient__get_full_name, :label => I18n.t(:patient, {:scope=>[:patient]}), :width => 150,
          :width => 180,
          # [20121121] For the combo-boxes to have a working query after the 4th char is entered in the edit widget,
          # a lambda statement must be used. Using a pre-computed scope from the Model class prevents Netzke
          # (as of this version) to append the correct WHERE clause to the scope itself (with an inline lambda, instead, it works).
          :scope => lambda { |rel| rel.where(:is_suspended => false).order("surname ASC, name ASC") },
          :sorting_scope => :sort_schedule_by_patient
        },
        { :name => :notes,                  :label => I18n.t(:notes), :flex => 1 }
      ]
    )
  end
  # ---------------------------------------------------------------------------


  js_method :init_component, <<-JS
    function() {
      #{js_full_class_name}.superclass.initComponent.call(this);
                                                    // Stack another listener on top over the one defined in EntityGrid:
      this.getSelectionModel().on('selectionchange',
        function(selModel) {
          this.actions.managePatient.setDisabled( selModel.getCount() < 1 );
        },
        this
      );
                                                    // As soon as the grid is ready, sort it by default:
      this.on( 'viewready',
        function( gridPanel, eOpts ) {
          gridPanel.store.sort([ { property: 'date_schedule', direction: 'DESC' } ]);
        },
        this
      );
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------


  # Invokes "manage/:id/patient" according to the patient_id of the currently selected
  # Receipt row.
  #
  js_method :on_manage_patient, <<-JS
    function() {
      var fld = this.getSelectionModel().selected.first().data;
      var managePath = this.targetForPatientManage.replace( '-1', fld[ 'patient__get_full_name' ] );
      this.setDisabled( true );
      location.href = managePath;
    }
  JS
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
end
