#%w[rubygems sinatra data_mapper].each{ |r| require r }
require 'sinatra'
require 'json'
require 'data_mapper'
#require 'dm-sqlite-adapter'
require 'dm-postgres-adapter'
require 'bcrypt'


DataMapper::Logger.new($stdout, :debug)
#DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

configure :development do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")
end

configure :production do
  DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_IVORY_URL'])
end

class User
  include DataMapper::Resource

  property :id, String, :key => true
  property :name, String
  property :email, String, :format => :email_address, :required => true
  property :password, BCryptHash, :required => true
  property :token, String
  property :created_by, String
  property :last_updated_by, String
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :groups, :through => Resource
  has n, :projects, :through => Resource

  def generate_token!
    self.token = SecureRandom.urlsafe_base64(64)
    self.save! #persist
  end

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
  has n, :users, :through => Resource

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
  has n, :users, :through => Resource
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




DataMapper.finalize

def authenticate!
  @user = User.first(:token => @access_token)
  halt 403 unless @user
end

before do
  begin
    if request.env["HTTP_ACCESS_TOKEN"].is_a?(String)
      @access_token = request.env["HTTP_ACCESS_TOKEN"]
    end

    if request.body.read(1)
      request.body.rewind
      @request_payload = JSON.parse request.body.read, { symbolize_names: true}
      #puts @request_payload

    end

  rescue JSON::ParserError => e
    request.body.rewind
    puts "The body #{request.body.read} was not JSON"
  end
end

get '/heartbeat' do
  response = {status: 'alive'}
  status 200
  content_type :json
  body response.to_json
end

post '/login' do
  params = @request_payload[:user]

  user = User.first(:email => params[:email])
  if user.password == params[:password]
    if(user.token == nil)
      user.generate_token!
    end
    group = Group.first(:name => 'Kroger')
    user.groups << group
    user.save
    puts group
    response = {token: user.token, group: group} #giving user back a token

  else
    #tell user they aren't logged in
    response = {error: 'You arent logged in'}
  end
  status 200
  content_type :json
  body response.to_json
end

get '/user/groups' do
  authenticate!

  response = {user: @user.id, groups: @user.groups}

  status 200
  content_type :json
  body response.to_json
end

get '/groups/:group_id/projects' do
  authenticate!

  group = Group.first(:id => params[:group_id])
  response = {projects: group.projects}

  status 200
  content_type :json
  body response.to_json
end

get '/groups/:group_id/hackathons' do
  authenticate!

  group = Group.first(:id => params[:group_id])
  response = {hackathons: group.hackathons}

  status 200
  content_type :json
  body response.to_json
end
