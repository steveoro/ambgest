# Load the rails application
require File.expand_path('../application', __FILE__)

require 'framework/version'


# -- AgeX-specific stuff: --

AGEX_FRAMEWORK_VERSION  = Version::FULL unless defined? AGEX_FRAMEWORK_VERSION
AGEX_APP                = 'ambgest' unless defined? AGEX_APP
AGEX_APP_NAME           = 'AmbGest 3' unless defined? AGEX_APP_NAME
AGEX_APP_LOGO           = 'ambgest_logo_h43.png' unless defined? AGEX_APP_LOGO

AGEX_FEATURES = {
#  (configure here additional features) 
#  :enable_drag_n_drop_support => true      # (TODO) 
} unless defined?(AGEX_FEATURES)

LOCALES = {'it' => 'it-IT', 'en' => 'en-US'}.freeze

# Set this to false to enable the self-destruct sequence on application timeout expiring.
DISABLE_SELF_DESTRUCT = true unless defined?(DISABLE_SELF_DESTRUCT)
# ---------------------------------------------------------------------------


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
