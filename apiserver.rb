#!/usr/bin/env ruby
require 'sinatra/base'
require 'json'
require 'securerandom' #for uuid generation
require_relative 'sign.rb'

class SignApiServer < Sinatra::Base

  conf_file = File.read("./sign.conf") #this can be dangerous if the file gets too big but our conf file should always be really small
  conf_json = JSON.parse conf_file

  #Old options, these should be handled by the rack/unicorn/ngnix or what have you.
  #set :bind, conf_json["bindIp"]
  #set :port, conf_json["bindPort"]

  sign = SignHandler.new(conf_json["serialDevice"],conf_json["DefaultMessage"])

  before '/message/*' do #set default content-type for all api http responses
    content_type 'application/json'
  end

  get '/' do #returns the readme if anyone requests the server root
    content_type 'text/plain'
    File.read('./README.md')
  end

  post '/message/new' do #write a new message to the sign
    newid = SecureRandom.uuid
    request.body.rewind #I'm not sure what this does but sinatra docs say to do it
    data = JSON.parse request.body.read
    #I'm not sure if the line below is elegant or hackey
    data[:status] = sign.add(newid,data['message'],(data['color'].to_sym if data.has_key?('color')),(data['transition'].to_sym if data.has_key?('transition')),(data['timer'] if data.has_key?('timer'))) ? "on" : "off" #adds message to the sign and returns on/off status
    data[:uuid] = newid
    status  201 #return with HTTP status 201 since we're creating a new resource
    headers "Location" => url("/message/#{newid}") #set the HTTP Location header to the message object URI
    [:color,:transition,:timer].each do |key|
      data[key.to_s] = sign.messages[newid][key] unless data.has_key?(key.to_s) #set existing values if not sepcified in request
    end
   data.to_json
  end

  delete '/message/all' do #allow deleting all messages from localhost only
    request.ip == '127.0.0.1' ? sign.reset : (halt 401) #return 401 if requested is not localhost
    status 204
  end

  delete '/message/:uuid' do |id| #delete message [uuid]
    raise not_found if sign.messages[id] == nil
    sign.delete(id)
  end

  put '/message/:uuid' do |id| #change message [uuid]
    raise not_found if sign.messages[id] == nil
    request.body.rewind #ditto above
    data = JSON.parse request.body.read
    [:message,:color,:transition,:timer].each do |key|
      data[key.to_s] = sign.messages[id][key] unless data.has_key?(key.to_s) #set existing values if not sepcified in request
    end
    #the "add" method from the sign class doesn't care if you're adding a new message or updating an existing one
    data[:status] = sign.add(id,data['message'],(data['color'].to_sym if data.has_key?('color')),(data['transition'].to_sym if data.has_key?('transition')),(data['timer'] if data.has_key?('timer'))) ? "on" : "off"
    data[:uuid] = id
    data.to_json
  end

  get '/message/all' do #allow viewing all messages from localhost only
    request.ip == '127.0.0.1' ? sign.messages.to_json : (halt 401)
  end

  get '/message/:uuid' do |id| #I'm not sure if this is useful or why anyone would need it but I'm including it anyway just in case
    raise not_found if sign.messages[id] == nil
    data = Hash.new
    #data['message'] = sign.messages[id][0]
    #data['color'] = sign.messages[id][1]
    #data['transition'] = sign.messages[id][2]
    #data['timer'] = sign.messages[id][3] #todo make this return the time the message will be deleted
    data = sign.messages[id]
    data.to_json
  end

  not_found do
    content_type 'application/json'
    {:error => "resource not found"}.to_json
  end

  error 401 do
    content_type 'application/json'
    {:error => 'request must come from localhost'}.to_json
  end
end
