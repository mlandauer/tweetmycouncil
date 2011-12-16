# encoding: UTF-8
require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'The Tweet My Council App' do
  def app
    Sinatra::Application
  end

  it "says hello" do
    get '/'
    last_response.should be_ok
    last_response.body.should =~ /Hey there!/
  end

  describe "receiving email" do
    it "should record the email when it receives one and notify the person on Twitter" do
      EmailReply.should_receive(:create!).with(
        :from => "matthew@openaustralia.org",
        :in_reply_to_status_id => "123456",
        :in_reply_to_screen_name => "matthewlandauer",
        :subject => "The council replies to your tweet",
        :stripped_text => 'This is our reply',
        :full_text => 'This is our reply. And includes the footer').and_return(mock(:id => 24))

      Twitter.should_receive(:update).with("@matthewlandauer You've received a reply: http://tweetmycouncil.herokuapp.com/emails/24")
      post '/emails/receive',
        'from' => "matthew@openaustralia.org",
        'recipient' => "matthewlandauer+123456@tweetmycouncil.mailgun.org",
        'subject' => "The council replies to your tweet",
        'stripped-text' => 'This is our reply',
        'body-plain' => 'This is our reply. And includes the footer'
    end
  end

  describe "respond_to_tweet" do
    let(:user) { mock(:screen_name => "matthewlandauer") }

    it "should tell you to add geo information if the tweet doesn't have any" do
      status = mock(:geo => nil, :user => user, :id => 1001)
      Twitter.should_receive(:update).with("@matthewlandauer You need to add location information to your Tweet so I know where you are",
        :in_reply_to_status_id => 1001)

      respond_to_tweet(status)
    end

    context "tweet has geo information" do
      let (:status) do
        mock(:geo => mock(:coordinates => [-33.8736, 151.2076]), :user => user, :id => 1001, :id_str => "1001",
          :text => "This car has been abandoned for six months #tmyc")
      end

      it "should say there's a problem if geo2gov doesn't know the lga code" do
        Geo2gov.should_receive(:new).with("151.2076,-33.8736").and_return(mock(:lga_code => nil))
        Twitter.should_receive(:update).with("@matthewlandauer Oh no! Something's wrong. I can see where you are but I can't figure out which council you're in",
          :in_reply_to_status_id => 1001)

        respond_to_tweet(status)
      end

      it "should say there's a problem if the lga code isn't known in the authorities list" do
        Geo2gov.should_receive(:new).with("151.2076,-33.8736").and_return(mock(:lga_code => "LGA123"))
        Authority.should_receive(:find_by_lga_code).with(123).and_return(nil)
        Twitter.should_receive(:update).with("@matthewlandauer Oh no! Something's wrong. I can see where you are but I can't figure out which council you're in",
          :in_reply_to_status_id => 1001)

        respond_to_tweet(status)
      end

      it "should RT message if authority is on Twitter" do
        authority = mock(:twitter_screen_name => "@mycouncil")
        Geo2gov.should_receive(:new).with("151.2076,-33.8736").and_return(mock(:lga_code => "LGA123"))
        Authority.should_receive(:find_by_lga_code).with(123).and_return(authority)
        Twitter.should_receive(:update).with("@mycouncil RT @matthewlandauer: This car has been abandoned for six months ")

        respond_to_tweet(status)
      end

      it "should email the message if authority is on not Twitter but has email" do
        authority = mock(:twitter_screen_name => nil, :contact_email => "foo@bar.com", :name => "My Council")
        Geo2gov.should_receive(:new).with("151.2076,-33.8736").and_return(mock(:lga_code => "LGA123"))
        Authority.should_receive(:find_by_lga_code).with(123).and_return(authority)

        AuthorityMailer.should_receive(:email).with("foo@bar.com", "This car has been abandoned for six months ",
          "matthewlandauer", "1001").and_return(mock(:deliver => nil))
        Twitter.should_receive(:update).with("@matthewlandauer My Council is not on Twitter, I've emailed your tweet to foo@bar.com",
          :in_reply_to_status_id => 1001)
        respond_to_tweet(status)
      end

      it "should truncate the response if necessary" do
        authority = mock(:twitter_screen_name => nil, :contact_email => "foo@bar.com", :name => "My Council has a really stupidly long name that messes everything up")
        Geo2gov.should_receive(:new).with("151.2076,-33.8736").and_return(mock(:lga_code => "LGA123"))
        Authority.should_receive(:find_by_lga_code).with(123).and_return(authority)

        AuthorityMailer.should_receive(:email).with("foo@bar.com", "This car has been abandoned for six months ", "matthewlandauer",
          "1001").and_return(mock(:deliver => nil))
        Twitter.should_receive(:update).with("@matthewlandauer My Council has a really stupidly long name that messes everything up is not on Twitter, I've emailed your tweet to foo@bar…",
          :in_reply_to_status_id => 1001)
        respond_to_tweet(status)
      end

      it "should send back the web address if authority is not on Twitter and doesn't have an email" do
        authority = mock(:twitter_screen_name => nil, :contact_email => nil, :website_url => "http://mycouncil.gov.au",
          :name => "My Council")
        Geo2gov.should_receive(:new).with("151.2076,-33.8736").and_return(mock(:lga_code => "LGA123"))
        Authority.should_receive(:find_by_lga_code).with(123).and_return(authority)

        Twitter.should_receive(:update).with("@matthewlandauer My Council is not on Twitter, try http://mycouncil.gov.au",
          :in_reply_to_status_id => 1001)
        respond_to_tweet(status)
      end

      it "should just say that the council isn't on Twitter if there is no other way to contact them" do
        authority = mock(:twitter_screen_name => nil, :contact_email => nil, :website_url => nil,
          :name => "My Council")
        Geo2gov.should_receive(:new).with("151.2076,-33.8736").and_return(mock(:lga_code => "LGA123"))
        Authority.should_receive(:find_by_lga_code).with(123).and_return(authority)

        Twitter.should_receive(:update).with("@matthewlandauer My Council is not on Twitter",
          :in_reply_to_status_id => 1001)
        respond_to_tweet(status)
      end
    end

    it "should shorten the RT to council to 140 characters and add a link to the original tweet if necessary" do
      status = mock(:geo => mock(:coordinates => [-33.8736, 151.2076]), :user => user, :id => 1001, :id_str => "1001",
          :text => "12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234 #tmyc")
      # This message is the maximum possible in Twitter
      status.text.length.should == 140

      authority = mock(:twitter_screen_name => "@mycouncil")
      Geo2gov.should_receive(:new).with("151.2076,-33.8736").and_return(mock(:lga_code => "LGA123"))
      Authority.should_receive(:find_by_lga_code).with(123).and_return(authority)
      # The link at the end will be shortened to 20 characters (by Twitter)
      Twitter.should_receive(:update).with("@mycouncil RT @matthewlandauer: 12345678901234567890123456789012345678901234567890123456789012345678901234567890123456… https://twitter.com/matthewlandauer/status/1001")

      respond_to_tweet(status)
    end
  end
end
