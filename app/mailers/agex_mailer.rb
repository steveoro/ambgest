=begin
  
= AgexMailer

  - version:  3.03.06.20130328
  - author:   Steve A.

  Mailer base custom class for the Agex framework.
=end
class AgexMailer < ActionMailer::Base

  # Internal Mailer address for the "From" field of the e-mails. Usually something like "no-reply@fasar.software.it"
  #
  AGEX_ADMIN_EMAIL = "AgeX Mailer <fasar.software@email.it>"

  default :from => AGEX_ADMIN_EMAIL


  # "Exception intercepted" message.
  #
  def exception_mail( user_name, error_description, error_backtrace )
    @description = error_description
    @backtrace   = error_backtrace
    @user_name   = user_name

    mail(
      :to => AGEX_ADMIN_EMAIL,
      :subject => "[#{AGEX_APP_NAME}@#{ENV['HOSTNAME']}] AgexMailer EXCEPTION: '#{error_description}'.",
      :date => Time.now
    )
  end
  # ---------------------------------------------------------------------------


  # Action notify message.
  #
  def action_notify_mail( user_name, action_name, action_description )
    @name = action_name
    @description = action_description
    @user_name = user_name

    mail(
      :to => AGEX_ADMIN_EMAIL,
      :subject => "[#{AGEX_APP_NAME}@#{ENV['HOSTNAME']}] AgexMailer action '#{action_name}'",
      :date => Time.now
    )
  end
end
# -----------------------------------------------------------------------------
