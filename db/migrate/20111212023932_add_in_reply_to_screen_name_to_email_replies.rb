class AddInReplyToScreenNameToEmailReplies < ActiveRecord::Migration
  def self.up
    add_column :email_replies, :in_reply_to_screen_name, :string
  end

  def self.down
    remove_column :email_replies, :in_reply_to_screen_name
  end
end
