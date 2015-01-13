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
