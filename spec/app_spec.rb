require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'The Tweet My Council App' do
  def app
    Sinatra::Application
  end

  it "says hello" do
    get '/'
    last_response.should be_ok
    last_response.body.should == 'Hello World!'
  end
end