#!/usr/bin/env ruby

require 'sinatra'
require 'tweetstream'
require 'yaml'

configuration = YAML.load_file('configuration.yaml')

EM.schedule do
  # Just good enough for a local dev install at the moment
  TweetStream.configure do |config|
    config.consumer_key = configuration['consumer']['key']
    config.consumer_secret = configuration['consumer']['secret']
    config.oauth_token = configuration['oauth']['token']
    config.oauth_token_secret = configuration['oauth']['token_secret']
    config.auth_method = :oauth
  end

  client = TweetStream::Client.new
  #client.track('#tmyc') do |status|
  client.sample do |status|
    # Just writes out a text of a random tweet for the time being
    puts status.text
  end
  client.on_error do |message|
    p message
  end
end

EM.error_handler{ |e|
  puts "Error raised during event loop: #{e.message}"
}

