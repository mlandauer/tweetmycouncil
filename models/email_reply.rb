class EmailReply < ActiveRecord::Base
  def in_reply_to_twitter_url
    "http://twitter.com/#{in_reply_to_screen_name}/status/#{in_reply_to_status_id}"
  end
end
