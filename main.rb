require 'sinatra'
require 'json'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'bcrypt'


DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class User
  include DataMapper::Resource
  include BCrypt

  property :id, String, :key => true
  property :name, String
  property :email, String
  property :password, BCryptHash
  property :created_by, String
  property :last_updated_by, String
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :usergroups
  has n, :groups, :through => :usergroups

  has n, :userprojects
  has n, :projects, :through => :userprojects

end

class Project
  include DataMapper::Resource

  property :id, String, :key => true
  property :group_id, String
  property :hackathon_id, String
  property :name, String
  property :description, Text
  property :status, String
  property :avatar, String
  property :repo, String
  property :created_by, String
  property :last_updated_by, String
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :group
  belongs_to :hackathon

  has n, :userprojects
  has n, :users, :through => :userprojects

end



class Group
  include DataMapper::Resource

  property :id, String, :key => true
  property :name, String
  property :created_by, String
  property :last_updated_by, String
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :hackathons
  has n, :projects

  has n, :usergroups
  has n, :users, :through => :usergroups
end

class Hackathon
  include DataMapper::Resource

  property :id, String, :key => true
  property :group_id, String
  property :name, String
  property :hack_date, DateTime
  property :created_by, String
  property :last_updated_by, String
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :group

  has n, :projects

end

class Usergroup
  include DataMapper::Resource
  property :id, Serial
  property :created_at, DateTime

  belongs_to :user
  belongs_to :group

end

class Userproject
  include DataMapper::Resource
  property :id, Serial
  property :created_at, DateTime

  belongs_to :user
  belongs_to :project

end


DataMapper.finalize



get '/heartbeat' do
  response = {status: 'alive'}
  status 200
  content_type :json
  body response.to_json
end
