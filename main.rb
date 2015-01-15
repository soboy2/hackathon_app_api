require 'sinatra'
require 'json'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'bcrypt'


DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

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
  @user = User.first(:token => @request_payload[:token])
  halt 403 unless @user
end

before do
  begin
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
    user.generate_token!
    group = user.groups.create(:name => 'Kroger')
    puts group
    {token: user.token}.to_json #giving user back a token
    #return user groups
  else
    #tell user they aren't logged in
    {error: 'You arent logged in'}.to_json
  end
end

get '/protected' do
  authenticate!
  #do_something_with_user(@user)
end
