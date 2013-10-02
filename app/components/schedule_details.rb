#
# Custom Receipt details Form component implementation
#
# - author: Steve A.
# - vers. : 3.05.05.20131002
#
class ScheduleDetails < Netzke::Basepack::FormPanel

  model 'Schedule'

  js_properties(
    :prevent_header => true,
    :header => false,
    :border => false
  )


  def configuration
   super.merge(
      :persistence => true,
      :width => 490
   )
  end


  items [
    {
      :column_width => 1.00, :border => false, :defaults => { :label_width => 120 },
      :items => [
        { :name => :date_schedule,          :field_label => I18n.t(:date_schedule, {:scope=>[:schedule]}),
          :format => 'Y-m-d', :default_value => DateTime.now, :width => 350
        },
        { :name => :must_insert,            :field_label => I18n.t(:must_insert, {:scope=>[:schedule]}),
          :field_style => 'min-height: 13px; padding-left: 13px;', :unchecked_value => 'false' 
        },
        { :name => :must_move,              :field_label => I18n.t(:must_move, {:scope=>[:schedule]}),
          :field_style => 'min-height: 13px; padding-left: 13px;', :unchecked_value => 'false'
        },
        { :name => :must_call,              :field_label => I18n.t(:must_call, {:scope=>[:schedule]}),
          :field_style => 'min-height: 13px; padding-left: 13px;', :unchecked_value => 'false'
        },
        { :name => :is_done,                :field_label => I18n.t(:is_done, {:scope=>[:schedule]}),
          :field_style => 'min-height: 13px; padding-left: 13px;', :unchecked_value => 'false'
        },

        { :name => :patient__get_full_name, :field_label => I18n.t(:patient, {:scope=>[:patient]}),
          :width => 350, :field_style => 'font-size: 110%; font-weight: bold;',
          # [20121121] For the combo-boxes to have a working query after the 4th char is entered in the edit widget,
          # a lambda statement must be used. Using a pre-computed scope from the Model class prevents Netzke
          # (as of this version) to append the correct WHERE clause to the scope itself (with an inline lambda, instead, it works).
          :scope => lambda { |rel| rel.where(:is_suspended => false).order("surname ASC, name ASC") }
        },
        { :name => :notes,                  :field_label => I18n.t(:notes), :width => 400,
          :xtype => :textareafield
        }
      ]
    }
  ]

  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
end
