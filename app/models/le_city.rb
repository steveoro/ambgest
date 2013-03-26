class LeCity < ActiveRecord::Base

  validates_presence_of   :name
  validates_length_of     :name, :within => 1..40
  validates_uniqueness_of :name, :scope => :zip, :message => :already_exists

  validates_length_of     :zip, :maximum => 6

  validates_presence_of   :area
  validates_length_of     :area, :within => 1..40

  validates_presence_of   :country
  validates_length_of     :country, :within => 1..40

  validates_presence_of   :country_code
  validates_length_of     :country_code, :within => 1..4
  #-----------------------------------------------------------------------------
  #++

  # Computes a shorter description for the name associated with this data
  def get_full_name
    [
      (name.empty? ? nil : name),
      (zip.empty? ? nil : zip),
      (area.empty? ? nil : area)
    ].compact.join(", ")
  end

  # Computes a verbose or formal description for the name associated with this data
  def get_verbose_name
    country_desc = (self.country_code.nil? || (self.country_code == "I")) ? "" :
                   " #{self.country} (#{self.country_code})"
    get_full_name + country_desc
  end
  # ----------------------------------------------------------------------------
  #++
end
