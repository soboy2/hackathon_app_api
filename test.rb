ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require_relative 'main.rb'

include Rack::Test::Methods

def app
  Sinatra::Application
end

describe "Get /heartbeat" do
  before { get '/heartbeat' }
  let(:response) { JSON.parse(last_response.body) }


  it "should return json" do
    last_response.headers['Content-Type'].must_equal 'application/json'
  end

  it { response['status'].must_equal 'alive'}
end

describe User do
  let(:user) { User.new }

  it "is an instance of User" do
    assert_instance_of User, user
  end

  it "is a valid User" do
    user.valid?.must_equal true
  end

end

describe Project do
  let(:project) { Project.new }

  it "is an instance of Project" do
    assert_instance_of Project, project
  end

  it "is a valid Project" do
    project.valid?.must_equal true
  end
end

describe Hackathon do
  let(:hackathon) { Hackathon.new(name: 'Hackathon 3', created_by: 'Eric G') }

  it "is an instance of Hackathon" do
    assert_instance_of Hackathon, hackathon
  end

  it "is a valid Hackathon" do
    puts hackathon
    hackathon.valid?.must_equal true
  end
end

describe Group do
  let(:group) { Group.new }

  it "is an instance of Group" do
    assert_instance_of Group, group
  end

  it "is a valid Group" do
    group.valid?.must_equal true
  end
end
