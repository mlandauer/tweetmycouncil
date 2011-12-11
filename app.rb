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
  def self.find_by_location(location)
    geo2gov_response = Geo2gov.new(location)
    lga_code = geo2gov_response.lga_code[3..-1] if geo2gov_response.lga_code
    find_by_lga_code(lga_code.to_i) if lga_code
  end
end

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

# Set config from local file for development (and use environment variables on Heroku)
if File.exists? 'configuration.yaml'
  configuration = YAML.load_file('configuration.yaml')
  ENV['CONSUMER_KEY'] = configuration['consumer']['key']
  ENV['CONSUMER_SECRET'] = configuration['consumer']['secret']
  ENV['OAUTH_TOKEN'] = configuration['oauth']['token']
  ENV['OAUTH_TOKEN_SECRET'] = configuration['oauth']['token_secret']
end

def response_to_tweet(status, authority)
  if status.geo
    if authority
      if authority.twitter_screen_name
        nil
      elsif authority.contact_email
        "#{authority.name} is not on Twitter, I've emailed your tweet to #{authority.contact_email}"
      elsif authority.website_url
        "#{authority.name} is not on Twitter, try #{authority.website_url}"
      else
        "#{authority.name} is not on Twitter"
      end
    else
      "Oh no! Something's wrong. I can see where you are but I can't figure out which council you're in"
    end
  else
    "You need to add location information to your Tweet so I know where you are"
  end
end

def respond_to_tweet(status)
  if status.geo
    authority = Authority.find_by_location("#{status.geo.coordinates[1]},#{status.geo.coordinates[0]}")
    if authority
      if authority.twitter_screen_name
        Twitter.update("#{authority.twitter_screen_name} RT @#{status.user.screen_name}: #{status.text.gsub('#tmyc', '')}")
      elsif authority.contact_email
        AuthorityMailer.email(authority.contact_email, status.text.gsub('#tmyc', ''), "https://twitter.com/#{status.user.screen_name}/status/#{status.id_str}").deliver
      end
    end
  end

  # Now send a response back to the user that sent the original tweet (if necessary)
  r = response_to_tweet(status, authority)
  Twitter.update("@#{status.user.screen_name} #{r}", :in_reply_to_status_id => status.id.to_i) if r    
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
    respond_to_tweet(status)
  end
  client.on_error do |message|
    p message
  end
end

EM.error_handler{ |e|
  puts "Error raised during event loop: #{e.message}"
}
