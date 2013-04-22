class Article < ActiveRecord::Base

  belongs_to :le_user, :class_name => "LeUser", :foreign_key => "user_id"
  # [Steve, 20120212] Validating le_user fails always because of validation requirements inside LeUser (password & salt)
#  validates_associated :le_user                    # (Do not enable this for LeUser)

  validates_presence_of :title
  validates_length_of :title, :within => 1..80

  validates_presence_of :entry_text
  validates_presence_of :le_user


  scope :permalinks, where(:is_sticky => true)

  scope :sort_article_by_user, lambda { |dir| order("le_users.name #{dir.to_s}, articles.title #{dir.to_s}") }

  #--
  # Note: boolean validation via a typical...
  #
  #   validates_format_of :is_sticky_before_type_cast, :with => /[01]/, :message=> :must_be_0_or_1
  #
  # ...must *not* be used since the ExtJS grids convert internally the values from string/JSON text.


  # ----------------------------------------------------------------------------
  # Base methods:
  # ----------------------------------------------------------------------------
  #++

  # Computes a shorter description for the name associated with this data
  def get_full_name
    self.title
  end

  # Retrieves the user name associated with this article
  def user_name
    name = self.le_user.nil? ? '' : self.le_user.name
  end
  # ----------------------------------------------------------------------------
  #++

  # Checks and sets unset fields to default values.
  #
  # === Parameters:
  # - +params_hash+ => Hash of additional parameter values for attribute defaults override.
  #
  def preset_default_values( params_hash = {} )
    unless self.le_user || params_hash[:user_id].blank?  # Set current user only if not set
      begin
        if params_hash[:user_id]
          self.user_id = params_hash[:user_id].to_i
        end
      rescue
        self.user_id = nil
      end
    end
    self
  end
  # ----------------------------------------------------------------------------
end
