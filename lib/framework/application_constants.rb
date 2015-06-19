=begin

= Custom (global) application constants.

  - version:  1.00.001
  - author:   Steve A.

=end

#--
# [Steve, 20080414]
# ** DO NOT CHANGE ANY OF THE FOLLOWING UNLESS YOU KNOW WHAT YOU'RE DOING!! **
#++

# Current AgeX Framework version
AGEX_FRAMEWORK_VERSION  = Version::FULL unless defined? AGEX_FRAMEWORK_VERSION

# App-name, lowercase, used in shared modules or sub-projects
AGEX_APP                = 'ambgest' unless defined? AGEX_APP

# "Displayable" App-name, used in shared modules or sub-projects
AGEX_APP_NAME           = 'AmbGest 3' unless defined? AGEX_APP_NAME

# Logo image file for this App, used in shared modules or sub-projects
AGEX_APP_LOGO           = 'ambgest_logo_h43.png' unless defined? AGEX_APP_LOGO

# Additional toggles/flags for plug-in features:
AGEX_FEATURES = {
#  (configure here additional features)
#  :enable_drag_n_drop_support => true      # (TODO)
} unless defined?(AGEX_FEATURES)

# Accepted and defined locales
LOCALES = {'it' => 'it-IT', 'en' => 'en-US'}.freeze
I18n.enforce_available_locales = true

# Set this to false to enable the self-destruct sequence on application timeout expiring.
DISABLE_SELF_DESTRUCT = true unless defined?(DISABLE_SELF_DESTRUCT)
# ---------------------------------------------------------------------------


# Format string according to ExtJS4's Ext.form.field.Date
# Should match the format below and should be easily sortable.
AGEX_FILTER_DATE_FORMAT_EXTJS  = 'Y-m-d' unless defined? AGEX_FILTER_DATE_FORMAT_EXTJS

# Format string used for both SQL's WHERE-clause and Ruby's strftime().
# Should match the format above and should be easily sortable.
AGEX_FILTER_DATE_FORMAT_SQL    = '%Y-%m-%d' unless defined? AGEX_FILTER_DATE_FORMAT_SQL
# ----------------------------------------------------------------------------


Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
