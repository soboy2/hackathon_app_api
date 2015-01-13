require 'sinatra'
require 'json'

get '/heartbeat' do
  response = {status: 'alive'}
  status 200
  content_type :json
  body response.to_json
end
