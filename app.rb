#!/usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'

require 'sinatra'
require 'tweetstream'
require 'yaml'
require 'twitter'
require 'httparty'
require 'geo2gov'

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
      puts "Found geo information"
      responses = [
        "Crikey! I can see you",
        "I've found your flamin location"
      ]
      lga_code = Geo2gov.new(status.geo.coordinates[0], status.geo.coordinates[1]).lga_code
      if lga_code
        puts "Found LGA code"
        response = "#{responses.sample}: #{lga_code}"
      else
        response = "#{responses.sample}: #{status.geo.coordinates}"
      end
    else
      response = no_geo_response
    end
    puts "Responding with \"@#{status.user.screen_name} #{response} (#{rand(500)})\""
    Twitter.update("@#{status.user.screen_name} #{response} (#{rand(500)})", :in_reply_to_status_id => status.id.to_i)
  end
  client.on_error do |message|
    p message
  end
end

EM.error_handler{ |e|
  puts "Error raised during event loop: #{e.message}"
}

def no_geo_response
  responses = [
    "I can't find where the bloody hell you are",
    "Can't find any location data on your tweet, mate",
    "Strewth, you need to add location data"
  ]
  response = responses.sample
end
