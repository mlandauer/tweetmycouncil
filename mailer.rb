require 'action_mailer'

if ENV['MAILGUN_SMTP_LOGIN'] && ENV['MAILGUN_SMTP_PASSWORD']
  ActionMailer::Base.smtp_settings = {
    :port           => ENV['MAILGUN_SMTP_PORT'],
    :address        => ENV['MAILGUN_SMTP_SERVER'],
    :user_name      => ENV['MAILGUN_SMTP_LOGIN'],
    :password       => ENV['MAILGUN_SMTP_PASSWORD'],
    :domain         => 'tweetmycouncil.herokuapp.com',
    :authentication => :plain
  }
else
  # Send to Mailcatcher for development because it rocks!
  # gem install mailcatcher
  ActionMailer::Base.smtp_settings = {
    :address => "localhost", :port => 1025
  }
end

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.view_paths= File.join(File.dirname(__FILE__), 'views')

class AuthorityMailer < ActionMailer::Base
  def email(to, message_text, screen_name, message_id)
    @message_text, @screen_name, @message_id = message_text, screen_name, message_id

    mail(:to => to, :bcc => "contact@openaustralia.org", :from => "#{screen_name}+#{message_id}@tweetmycouncil.mailgun.org",
      :subject => message_text)
  end
end

# An example of how to use it
#AuthorityMailer.email("matthew@openaustralia.org", "Hello Council!", "matthewlandauer", "142786606087155712").deliver
