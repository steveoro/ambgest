#
# Specialized master-detail component implementation.
#
# - author: Steve A.
# - vers. : 3.03.03.20130326
#
# == Params
#
# :+record_id+ must be set during component configuration and must point to the current header's Patient.id
#
class FilteredPatientManagePanel < Netzke::Basepack::BorderLayoutPanel

  js_properties(
    :prevent_header => true,
    :header => false,
    :border => true
  )


  def configuration
    super.merge(
      :persistence => true,
      :min_width => 900,
      :items => [
        :patient_header.component( :region => :north,  :split => true ),
        :filtered_composite_view.component( :region => :center )
      ]
    )
  end
  # ---------------------------------------------------------------------------

  MANAGE_HEADER_HEIGHT = 274                        # this is referenced also more below

  component :patient_header do
    {
      :class_name => "PatientDetails",
      :mode => :lockable,
      :record_id => config[:record_id],
      :height => MANAGE_HEADER_HEIGHT
    }
  end
  # ---------------------------------------------------------------------------


  component :filtered_composite_view do
    {
      :class_name => "FilteredTabbedDualPanel",
      :width => "98%",
      :height => config[:height] - MANAGE_HEADER_HEIGHT,
      :view_config => {
        :force_fit => true # force the columns to occupy all the available width
      },
                                                    # --- Tab1 grid configuration:
      :class_tab1 => "AppointmentsGrid",
      :title_tab1 => I18n.t(:appointments, {:scope=>[:appointment]}),
      :scope_sql_tab1 => "patient_id = ? AND ( (DATE_FORMAT(date_schedule,'#{AGEX_FILTER_DATE_FORMAT_SQL}') >= ? AND DATE_FORMAT(date_schedule,'#{AGEX_FILTER_DATE_FORMAT_SQL}') <= ?) OR date_schedule IS NULL )",
                                                    # --- Tab2 grid configuration:
      :class_tab2 => "ReceiptsGrid",
      :title_tab2 => I18n.t(:receipts, {:scope=>[:receipt]}),
      :scope_sql_tab2 => "patient_id = ? AND ( (DATE_FORMAT(date_receipt,'#{AGEX_FILTER_DATE_FORMAT_SQL}') >= ? AND DATE_FORMAT(date_receipt,'#{AGEX_FILTER_DATE_FORMAT_SQL}') <= ?) OR date_receipt IS NULL )",

      :active_tab => 0,
      :record_id => config[:record_id],
      :strong_default_attrs => {
        :patient__get_full_name => config[:record_id]
      },
      :filtering_date_start => config[:filtering_date_start],
      :filtering_date_end   => config[:filtering_date_end]
    }
  end
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
end
