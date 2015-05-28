module Version
  # [Steve, 20080414]
  # ** DO NOT CHANGE THE FOLLOWING UNLESS YOU KNOW WHAT YOU'RE DOING!! **
  MAJOR   = '3.06'
  MINOR   = '00'
  BUILD   = '20150528'

  # Internal constant used to discriminate between all the existing and
  # running versions of the AgeX framework.
  FULL    = "#{MAJOR}.#{MINOR}.#{BUILD}"

  # Compact version of the versioning costant.
  COMPACT = "#{MAJOR.gsub('.','')}#{MINOR}"

  # Current internal DB version (indipendent from migrations and framework release)
#  DB      = "3.05.08"
end
