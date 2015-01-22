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
  property :token, Text
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

post '/users' do
  params = @request_payload[:user]
  if params.nil?
    status 400
  else
    user = User.first_or_create(
            :name => params[:name],
            :password => params[:password],
            :id => params[:id],
            :email => params[:email],
            :created_at => Time.now,
            :updated_at => Time.now
          )
    user.save
    status 200
    puts "***** added a new user @ " + user.id.to_s
    content_type :json
    response = {status: 'success', id: user.id}
    body response.to_json
  end
end

post '/projects' do
  params = @request_payload[:project]
  if params.nil?
    status 400
  else
    project = Project.first_or_create(
                :id => params[:id],
                :name => params[:name],
                :description => params[:description],
                :status => params[:status],
                :created_at => Time.now,
                :updated_at => Time.now
              )
    project.save
    status 200
    puts "***** added a new project @ " + project.id.to_s
    content_type :json
    response = {status: 'success', id: project.id}
    body response.to_json
  end
end

post '/hackathons' do
  params = @request_payload[:hackathon]
  if params.nil?
    status 400
  else
    hackathon = Hackathon.first_or_create(
                  :id => params[:id],
                  :name => params[:name] ,
                  :hack_date => Date.parse(params[:hack_date]),
                  :created_at => Time.now,
                  :updated_at => Time.now
              )
    hackathon.save
    status 200
    puts "***** added a new  @ " + hackathon.id.to_s
    content_type :json
    response = {status: 'success', id: hackathon.id}
    body response.to_json
  end
end

post '/groups' do
  params = @request_payload[:group]
  if params.nil?
    status 400
  else
    group = Group.first_or_create(
    :id => params[:id],
    :name => params[:name] ,
    :created_at => Time.now,
    :updated_at => Time.now
    )
    group.save
    status 200
    puts "***** added a new  @ " + group.id.to_s
    content_type :json
    response = {status: 'success', id: group.id}
    body response.to_json
  end
end

post '/login' do
  params = @request_payload[:user]
  puts "***** User " + params[:email] +" attempting to login"
  user = User.first(:email => params[:email])
  if user.password == params[:password]
    if(user.token == nil)
      user.generate_token!
    end
    group = Group.first(:name => 'Kroger')
    user.groups << group
    user.save
    puts group
    response = {token: user.token, id: user.id, name: user.name, email: user.email, group: group} #giving user back a token

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

#add a user to a group
post '/user/groups' do
  user = User.first(:id => @request_payload[:user_id])
  group = Group.first(:id => @request_payload[:group_id])

  user.groups << group
  if user.save
    status 200
    content_type :json
    response = {status: 'success'}
    body response.to_json
  else
    status 400
  end

end

#add a project to a group
post '/group/projects' do
  group = Group.first(:id => @request_payload[:group_id])
  project = Project.first(:id => @request_payload[:project_id])
  group.projects << project
  if group.save
    status 200
    content_type :json
    response = {status: 'success'}
    body response.to_json
  else
    status 400
  end
end

#add a hackathon to a group
post '/group/hackathons' do
  group = Group.first(:id => @request_payload[:group_id])
  hackathon = Hackathon.first(:id => @request_payload[:hackathon_id])
  group.hackathons << hackathon
  if group.save
    status 200
    content_type :json
    response = {status: 'success'}
    body response.to_json
  else
    status 400
  end
end
