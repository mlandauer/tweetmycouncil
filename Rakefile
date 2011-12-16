require 'sinatra/activerecord/rake'
require 'httparty'
require 'nokogiri'
require 'rspec/core/rake_task'

task :default => :spec

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ['--colour']
end

def google_spreadsheet_data
    f = HTTParty.get("https://spreadsheets.google.com/feeds/list/0AppM8FtCInYXdGxRZGpCY0t6eDV5aFNwSEFPWnJqV3c/od6/public/basic")
    records = []
    Nokogiri::XML(f.body).search('entry').each do |entry|
      title = entry.at('title').inner_text
      content = entry.at('content').inner_text

      b = content.split(", ").map{|a| a.split(": ")}
      h = Hash[*b.flatten]

      records << {:lga_code => title, :name => h["lganame"], :website_url => h["url"], :twitter_screen_name => h["twitteraccount"],
        :contact_email => h["email"]}
    end
    records
end

namespace :db do
  desc "load authorities data into database from Google Spreadsheet (DELETES OLD AUTHORITIES DATA!)"
  task :load do
    require './app'

    Authority.delete_all
    google_spreadsheet_data.each do |r|
      Authority.create!(r)
    end
  end

  namespace :load do
    desc "Spit out the Google Spreadsheet data to sanity check it (before running rake db:load)"
    task :preview do
      google_spreadsheet_data.each do |r|
        p r
      end
    end
  end
end
