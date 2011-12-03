#!/usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'

require 'sinatra'
require 'tweetstream'
require 'yaml'
require 'twitter'
require 'httparty'
require 'geo2gov'
require 'sinatra/activerecord'
require 'uri'
require './mailer'

# If we're on Heroku use its database else use a local sqlite3 database. Nice and easy!
db = URI.parse(ENV['DATABASE_URL'] || 'sqlite3:///development.db')

ActiveRecord::Base.establish_connection(
  :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
  :host     => db.host,
  :username => db.user,
  :password => db.password,
  :database => db.path[1..-1],
  :encoding => 'utf8'
)

# At this point, you can access the ActiveRecord::Base class using the
# "database" object:
#puts "the authorities table doesn't exist" if !database.table_exists?('authorities')

class Authority < ActiveRecord::Base
end

get "/" do
  "Hello World!"
end

# Set config from local file for development (and use environment variables on Heroku)
if File.exists? 'configuration.yaml'
  configuration = YAML.load_file('configuration.yaml')
  ENV['CONSUMER_KEY'] = configuration['consumer']['key']
  ENV['CONSUMER_SECRET'] = configuration['consumer']['secret']
  ENV['OAUTH_TOKEN'] = configuration['oauth']['token']
  ENV['OAUTH_TOKEN_SECRET'] = configuration['oauth']['token_secret']
end

EM.schedule do
  TweetStream.configure do |config|
    config.consumer_key = ENV['CONSUMER_KEY']
    config.consumer_secret = ENV['CONSUMER_SECRET']
    config.oauth_token = ENV['OAUTH_TOKEN']
    config.oauth_token_secret = ENV['OAUTH_TOKEN_SECRET']
    config.auth_method = :oauth
  end

  Twitter.configure do |config|
    config.consumer_key = ENV['CONSUMER_KEY']
    config.consumer_secret = ENV['CONSUMER_SECRET']
    config.oauth_token = ENV['OAUTH_TOKEN']
    config.oauth_token_secret = ENV['OAUTH_TOKEN_SECRET']
  end

  client = TweetStream::Client.new
  client.track('#tmyc') do |status|
    puts "Responding to tweet from @#{status.user.screen_name}"
    if status.geo
      puts "Found geo information: #{status.geo}"
      geo2gov_response = Geo2gov.new(status.geo.coordinates[0], status.geo.coordinates[1])
      lga_code = geo2gov_response.lga_code[3..-1] if geo2gov_response.lga_code
      if lga_code
        puts "Found LGA code #{lga_code}"
        authority = Authority.find_by_lga_code(lga_code.to_i)
        if authority
          if authority.twitter_screen_name
            Twitter.update("#{authority.twitter_screen_name} RT @#{status.user.screen_name}: #{status.text.gsub('#tmyc', '')}")
          elsif authority.contact_email
            AuthorityMailer.email(authority.contact_email, status.text, "https://twitter.com/#{status.user.screen_name}/status/#{status.id_str}").deliver
            Twitter.update(
              "@#{status.user.screen_name} #{authority.name} is not on Twitter, I've emailed your tweet to #{authority.contact_email}",
              :in_reply_to_status_id => status.id.to_i
            )
          elsif authority.website_url
            Twitter.update(
              "@#{status.user.screen_name} #{authority.name} is not on Twitter, try #{authority.website_url}",
              :in_reply_to_status_id => status.id.to_i
            )
          else
            Twitter.update(
              "@#{status.user.screen_name} #{authority.name} is not on Twitter",
              :in_reply_to_status_id => status.id.to_i
            )
          end
        else
          Twitter.update(
            "@#{status.user.screen_name} I found you but I don't know about LGA code #{lga_code}",
            :in_reply_to_status_id => status.id.to_i
          )
        end
      else
        Twitter.update("@#{status.user.screen_name} I found you but it doesn't look like you're in Australia",
          :in_reply_to_status_id => status.id.to_i
        )
      end
    else
      Twitter.update("@#{status.user.screen_name} You need to add location information to your Tweet so I know where you are",
        :in_reply_to_status_id => status.id.to_i
      )
    end
  end
  client.on_error do |message|
    p message
  end
end

EM.error_handler{ |e|
  puts "Error raised during event loop: #{e.message}"
}
