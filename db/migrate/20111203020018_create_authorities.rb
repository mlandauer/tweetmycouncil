class CreateAuthorities < ActiveRecord::Migration
  def self.up
    create_table :authorities do |t|
      t.integer :id
      t.string :name
      t.integer :lga_code
      t.string :contact_email
      t.string :twitter_screen_name
      t.string :website_url
    end
  end

  def self.down
    drop_table :authorities
  end
end
