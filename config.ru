require 'rubygems'
require 'bundler'

Bundler.require

require './app'

# So that log output doesn't get buffered
$stdout.sync = true

run Sinatra::Application