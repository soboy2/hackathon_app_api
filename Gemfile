source 'https://rubygems.org'
ruby ENV['CUSTOM_RUBY_VERSION'] || '2.0.0'

gem 'sinatra'
gem 'json'
gem 'data_mapper'
#gem 'dm-sqlite-adapter'
#gem 'dm-postgres-adapter'
gem 'bcrypt'

group :production do
  gem "pg"
  gem "dm-postgres-adapter"
end

group :development, :test do
  gem "sqlite3"
  gem "dm-sqlite-adapter"
end

group :test do
  gem 'minitest'
  gem 'rack-test'
  gem 'rake'
end
