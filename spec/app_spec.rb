require File.dirname(__FILE__) + '/../app'
require 'rspec'
require 'rack/test'

set :environment, :test

describe 'The Tweet My Council App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "says hello" do
    get '/'
    last_response.should be_ok
    last_response.body.should == 'Hello World!'
  end
end