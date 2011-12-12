class CreateEmailReplies < ActiveRecord::Migration
  def self.up
    create_table :email_replies do |t|
      t.integer :id
      t.string :from
      t.string :in_reply_to_status_id
      t.string :subject
      t.text :stripped_text
      t.text :full_text
    end
  end

  def self.down
    drop_table :email_replies
  end
end
