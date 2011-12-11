# If we're on Heroku use its database else use a local sqlite3 database. Nice and easy!
db = URI.parse(ENV['DATABASE_URL'] || 'sqlite3:///development.db')

ActiveRecord::Base.establish_connection(
  :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
  :host     => db.host,
  :username => db.user,
  :password => db.password,
  :database => db.path[1..-1],
  :encoding => 'utf8'
)
