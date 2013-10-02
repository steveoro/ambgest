#
# Specialized Patient details form component implementation
#
# - author: Steve A.
# - vers. : 3.05.05.20131002
#
class PatientDetails < Netzke::Basepack::FormPanel

  model 'Patient'

  js_properties(
    :prevent_header => true,
    :header => false,
    :border => false
  )


  def configuration
   super.merge(
      :persistence => true,
      :min_width => 900,
      :width => 1024
   )
  end


  items [
    {
      :layout => :column, :border => false,
      :items => [
        {
          :column_width => 1.00, :border => false, :defaults => { :label_width => 120 },
          :items => [
            {
              :xtype => :fieldcontainer, :field_label => I18n.t(:created_slash_updated_on),
              :layout => :column, :width => 900,
              :items => [
                {
                  :column_width => 0.45, :border => false, :defaults => { :label_width => 90 },
                  :items => [
                    {
                      :xtype => :fieldcontainer,
                      :layout => :hbox, :label_width => 125, :width => 380, :height => 18,
                      :items => [
                        { :name => :created_on,    :hide_label => true, :xtype => :displayfield, :width => 120},
                        { :xtype => :displayfield, :value => ' / ',     :margin => '0 2 0 2' },
                        { :name => :updated_on,    :hide_label => true, :xtype => :displayfield, :width => 120 }
                      ]
                    }
                  ]
                },
                {
                  :column_width => 0.55, :border => false, :defaults => { :label_width => 90 },
                  :items => [
                    
                  ]
                }
              ]
            },

            {
              :xtype => :fieldcontainer, :layout => :column, :width => 900,
              :items => [
                {
                  :column_width => 0.40, :border => false, :defaults => { :label_width => 120 },
                  :items => [
                      # [20121121] For the combo-boxes to have a working query after the 4th char is entered in the edit widget,
                      # a lambda statement must be used. Using a pre-computed scope from the Model class prevents Netzke
                      # (as of this version) to append the correct WHERE clause to the scope itself (with an inline lambda, instead, it works).
                      { :name => :le_title__get_full_name, :width => 200, :field_label => I18n.t(:title), 
                        :min_width => 150, :scope => lambda { |rel| rel.order("name ASC") }
                      },
                      { :xtype => :displayfield,        :value => ' ', :margin => '0 2 0 2' }, # vertical spacer
                      { :name => :surname,              :width => 380,
                        :field_style => 'font-size: 110%; font-weight: bold;'
                      },
                      { :xtype => :displayfield,        :value => ' ', :margin => '0 2 0 2' }, # vertical spacer
                      { :name => :name,                 :width => 380,
                        :field_style => 'font-size: 110%; font-weight: bold;'
                      },
                  ]
                },
                {
                  :column_width => 0.02, :border => false, :defaults => { :label_width => 90 },
                  :items => [
                      { :xtype => :displayfield,        :value => ' ', :margin => '0 2 0 2' }, # vertical spacer
                  ] # column spacer
                },
                {
                  :column_width => 0.58, :border => false, :defaults => { :label_width => 90 },
                  :items => [
                    { :name => :address,                  :field_label => I18n.t(:address), :width => 400,
                      :label_style => 'text-align: right;' },
                    { :name => :le_city__get_full_name,   :field_label => I18n.t(:le_city, {:scope=>[:activerecord, :models]}),
                      :width => 380 , :label_style => 'text-align: right;', :scope => lambda { |rel| rel.order("name ASC") }
                    },
                    {
                      :xtype => :fieldcontainer, :field_label => "#{I18n.t(:tax_code)} / #{I18n.t(:date_birth)}",
                      :layout => :hbox, :width => 600, :defaults => { :label_width => 125 },
                      :items => [
                        { :name => :tax_code, :hide_label => true, :width => 180 },
                        { :xtype => :displayfield,        :value => ' ',        :margin => '0 2 0 2' },
                        { :name => :date_birth,           :hide_label => true, :width => 200 }
                      ]
                    },

                    {
                      :xtype => 'checkboxgroup', :fieldLabel => I18n.t(:status, {:scope=>[:patient]}),
                      :cls => 'x-check-group-alt', :width => 700,
                      :defaults => { :hide_label => true, :field_style => 'min-height: 13px; padding-left: 13px;' },
                      :items => [
                          { :boxLabel => I18n.t(:is_a_firm, {:scope=>[:patient]}),
                            :name => :is_a_firm,
                            :unchecked_value => 'false'
                          },
                          { :boxLabel => I18n.t(:is_suspended, {:scope=>[:patient]}),
                            :name => :is_suspended,
                            :unchecked_value => 'false'
                          },
                          { :boxLabel => I18n.t(:is_fiscal, {:scope=>[:patient]}),
                            :name => :is_fiscal,
                            :unchecked_value => 'false'
                          }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              :xtype => :fieldcontainer, :field_label => I18n.t(:contact_info, {:scope=>[:patient]}),
              :layout => :column, :width => 900,
              :items => [
                {
                  :column_width => 0.34, :border => false, :defaults => { :label_width => 90 },
                  :items => [
                    { :name => :phone_home,       :field_label => I18n.t(:phone_home), :width => 250,
                      :field_style => 'color: blue;' },
                    { :field_style => 'color: blue;', :name => :e_mail, :field_label => I18n.t(:e_mail),
                      :width => 250 }
                  ]
                },
                {
                  :column_width => 0.33, :border => false, :defaults => { :label_width => 80 },
                  :items => [
                    { :name => :phone_work,       :field_label => I18n.t(:phone_work), :width => 253,
                      :field_style => 'color: blue;', :label_style => 'text-align: right;' },
                    { :name => :phone_fax,        :field_label => I18n.t(:phone_fax), :width => 253,
                      :field_style => 'color: blue;', :label_style => 'text-align: right;' }
                  ]
                },
                {
                  :column_width => 0.33, :border => false, :defaults => { :label_width => 80 },
                  :items => [
                    { :name => :phone_cell,       :field_label => I18n.t(:phone_cell), :width => 251,
                      :field_style => 'color: blue;', :label_style => 'text-align: right;' }
                  ]
                }
              ]
            },
            {
              :xtype => :fieldcontainer, :field_label => I18n.t(:receipt_preferences, {:scope=>[:patient]}),
              :layout => :column, :width => 900,
              :items => [
                {
                  :column_width => 0.27, :border => false, :defaults => { :label_width => 90 },
                  :items => [
                    { :name => :default_invoice_price,:field_label => I18n.t(:receipt_preferences_price, {:scope=>[:patient]}),
                      :width => 150 }
                  ]
                },
                {
                  :column_width => 0.73, :border => false, :defaults => { :label_width => 135 },
                  :items => [
                    { :name => :default_invoice_text, :field_label => I18n.t(:receipt_preferences_text, {:scope=>[:patient]}),
                      :width => 500, :label_style => 'text-align: right;', :resizable => true
                    },
                    { :name => :specify_neurologic_checkup,:field_label => I18n.t(:specify_neurologic_checkup, {:scope=>[:patient]}),
                      :label_style => 'text-align: right;', :field_style => 'min-height: 13px; padding-left: 13px;',
                      :unchecked_value => 'false'
                    },
                  ]
                }
              ]
            },
            {
              :xtype => :fieldcontainer, :field_label => I18n.t(:appointment_preferences, {:scope=>[:patient]}),
              :layout => :column, :width => 900,
              :items => [
                {
                  :column_width => 0.33, :border => false, :defaults => { :label_width => 90 },
                  :items => [
                    { :name => :preferred_days,:field_label => I18n.t(:preferred_days, {:scope=>[:patient]}),
                      :width => 250 }
                  ]
                },
                {
                  :column_width => 0.37, :border => false, :defaults => { :label_width => 90 },
                  :items => [
                    { :name => :preferred_times, :field_label => I18n.t(:preferred_times, {:scope=>[:patient]}),
                      :width => 280, :label_style => 'text-align: right;' }
                  ]
                },
                {
                  :column_width => 0.30, :border => false, :defaults => { :label_width => 130 },
                  :items => [
                    { :name => :appointment_freq, :field_label => I18n.t(:appointment_freq, {:scope=>[:patient]}),
                      :width => 180, :label_style => 'text-align: right;' }
                  ]
                }
              ]
            },
            { :name => :notes, :field_label => I18n.t(:notes), :height => 50, :width => 860,
              :resizable => true, :xtype => :textareafield }
          ]
        }
      ]
    }
  ]

  # ---------------------------------------------------------------------------
end
