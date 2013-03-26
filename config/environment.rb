# Load the rails application
require File.expand_path('../application', __FILE__)

  # Format string according to ExtJS4's Ext.form.field.Date
  # Should match the format below and should be easily sortable.
  #
  AGEX_FILTER_DATE_FORMAT_EXTJS  = 'Y-m-d';

  # Format string used for both SQL's WHERE-clause and Ruby's strftime().
  # Should match the format above and should be easily sortable.
  #
  AGEX_FILTER_DATE_FORMAT_SQL    = '%Y-%m-%d';
  # ----------------------------------------------------------------------------

# Initialize the rails application
Ambgest3::Application.initialize!
