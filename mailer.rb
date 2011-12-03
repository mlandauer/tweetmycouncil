require 'action_mailer'

if ENV['SENDGRID_USERNAME'] && ENV['SENDGRID_PASSWORD']
  ActionMailer::Base.smtp_settings = {
    :address        => 'smtp.sendgrid.net',
    :port           => '587',
    :authentication => :plain,
    :user_name      => ENV['SENDGRID_USERNAME'],
    :password       => ENV['SENDGRID_PASSWORD'],
    :domain         => 'heroku.com'
  }
else
  # Send to Mailcatcher for development because it rocks!
  # gem install mailcatcher
  ActionMailer::Base.smtp_settings = {
    :address => "localhost", :port => 1025
  }
end

ActionMailer::Base.delivery_method = :smtp

class AuthorityMailer < ActionMailer::Base
  def email(message_text, message_url)
    mail(:to => "matthew+tweetmycouncil@openaustralia.org", :from => "noreply@openaustraliafoundation.org.au",
      :subject => "A Citizen is contacting you via Twitter using Tweet My Council",
      :body => "A Citizen is contacting you via Twitter using Tweet My Council\n\n#{message_text}\n\nTo see their full message visit:\n#{message_url}\n\nTo reply to the Citizen directly please sign up for Twitter and respond to them there. Please DO NOT reply to this email.\n\nTo find out more about Tweet My Council visit:\nhttp://twitter.com/TweetMyCouncil")
  end
end

# An example of how to use it
#AuthorityMailer.email("Hello Council!", "https://twitter.com/matthewlandauer/status/142786606087155712").deliver
