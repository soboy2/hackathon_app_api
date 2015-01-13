require 'sinatra'
require 'json'
require 'data_mapper'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class User
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :email, String
  property :created_by, String
  property :last_update_by, String
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :usergroups
  has n, :groups, :through => :usergroups
end

class Project
  include DataMapper::Resource

  property :id, Serial
  property :group_id, Serial
  property :name, String
  property :description, Text
  property :status, String
  property :avatar, String
  property :repo, String
  property :created_by, String
  property :last_update_by, String
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :group

end

class Hackathon
  include DataMapper::Resource

  property :id, Serial
  property :group_id, Serial
  property :name, String
  property :hack_date, DateTime
  property :created_by, String
  property :last_update_by, String
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :group

end

class Group
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :created_by, String
  property :last_update_by, String
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :hackathons
  has n, :projects

  has n, :usergroups
  has n, :users, :through => :usergroups
end

class Usergroup
  include DataMapper::Resource
  property :id, Serial
  property :created_at, DateTime

  belongs_to :user
  belongs_to :group

end

DataMapper.finalize

get '/heartbeat' do
  response = {status: 'alive'}
  status 200
  content_type :json
  body response.to_json
end
