#!/usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'

require 'sinatra'
require "sinatra/json"
require 'tweetstream'
require 'yaml'
require 'twitter'
require 'httparty'
require 'geo2gov'
require 'sinatra/activerecord'
require 'uri'
require './mailer'
require './database'
require './models/authority'

get "/" do
  "Hello World!"
end

get '/api' do
  haml :api
end

get '/api/authorities.json' do
  json Authority.all
end

get '/api/authority.json' do
  if params[:location]
    json Authority.find_by_location(params[:location])
  elsif params[:lng] and params[:lat]
    json Authority.find_by_location("#{params[:lng]},#{params[:lat]}")
  end
end

# Receive email via Mailgun on Heroku
post '/email/receive' do
   # Log some of this
   puts "Received email from #{params['from']} to #{params['recipient']} with subject #{params['subject']}:"
   puts "Stripped text: #{params['stripped-text']}"

   render :text => "OK"
end

# Set config from local file for development (and use environment variables on Heroku)
if File.exists? 'configuration.yaml'
  configuration = YAML.load_file('configuration.yaml')
  ENV['CONSUMER_KEY'] = configuration['consumer']['key']
  ENV['CONSUMER_SECRET'] = configuration['consumer']['secret']
  ENV['OAUTH_TOKEN'] = configuration['oauth']['token']
  ENV['OAUTH_TOKEN_SECRET'] = configuration['oauth']['token_secret']
end

def response_to_tweet(status, authority)
  if status.geo.nil?
    "You need to add location information to your Tweet so I know where you are"
  elsif authority.nil?
    "Oh no! Something's wrong. I can see where you are but I can't figure out which council you're in"
  elsif authority.twitter_screen_name
    nil
  elsif authority.contact_email
    "#{authority.name} is not on Twitter, I've emailed your tweet to #{authority.contact_email}"
  elsif authority.website_url
    "#{authority.name} is not on Twitter, try #{authority.website_url}"
  else
    "#{authority.name} is not on Twitter"
  end
end

def respond_to_tweet(status)
  if status.geo
    authority = Authority.find_by_location("#{status.geo.coordinates[1]},#{status.geo.coordinates[0]}")
    if authority
      if authority.twitter_screen_name
        message = "#{authority.twitter_screen_name} RT @#{status.user.screen_name}: #{status.text.gsub(hashtag, '')}"
        if message.length > 140
          # Truncate the message to 116 characters so that we can append "... " and the url of the original tweet which
          # will get shortened to 20 characters
          message = message[0..115] + "... " + "https://twitter.com/#{status.user.screen_name}/status/#{status.id_str}"
        end
        Twitter.update(message)
      elsif authority.contact_email
        AuthorityMailer.email(authority.contact_email, status.text.gsub(hashtag, ''), "https://twitter.com/#{status.user.screen_name}/status/#{status.id_str}").deliver
      end
    end
  end

  # Now send a response back to the user that sent the original tweet (if necessary)
  r = response_to_tweet(status, authority)
  if r
    message = "@#{status.user.screen_name} #{r}"    
    message = message[0..136] + "..." if message.length > 140
    Twitter.update(message, :in_reply_to_status_id => status.id.to_i)
  end
end

def hashtag
  # The hashtag that the app uses
  # In development use a different hashtag so that we don't accidently send out rubbish to people using the real service
  settings.environment == :development ? '#tmycdev' : '#tmyc'
end

puts "Listening for the hashtag #{hashtag}..."

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
  client.track(hashtag) do |status|
    respond_to_tweet(status)
  end
  client.on_error do |message|
    p message
  end
end

EM.error_handler{ |e|
  puts "Error raised during event loop: #{e.message}"
}
