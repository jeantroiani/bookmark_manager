require 'sinatra'
require 'data_mapper'
require 'rack-flash'
require './lib/link' 
require './lib/tag'
require './lib/user'
require './app/data_mapper_setup'
require 'rest-client'

DataMapper.auto_migrate!


class Bookmark < Sinatra::Base	
	enable :sessions
	set :session_secret, 'super secret'
  use Rack::Flash
  use Rack::MethodOverride

	get '/' do 
		@links = Link.all
  	erb :index
end
  
  get'/links/new' do
  erb :"links/new"
end

post '/links' do
  tags = params["tags"].split(" ").map do |tag|
	Tag.first_or_create(:text => tag)
	end
	 @url = params[:url]
	 @title = params[:title]

  Link.create(:url => @url, :title => @title, :tags => tags)
  redirect to('/')
	end

	get '/tags/:text' do
  tag = Tag.first(:text => params[:text])
  @links = tag ? tag.links : []
  erb :index
	end

	get '/users/new' do
    @user = User.new
  erb :"users/new"
end

post '/users' do
  @user=user = User.create(:email => params[:email], 
              :password => params[:password],
              :password_confirmation => params[:password_confirmation])  
if @user.save
  session[:user_id] = @user.id
  redirect to('/')
 else
    flash.now[:errors] = @user.errors.full_messages
    erb :"users/new"
  end
end

helpers do

  def current_user    
    @current_user ||=User.get(session[:user_id]) if session[:user_id]
  end

end

get '/sessions/new' do
  erb :"sessions/new"
end

post '/sessions' do
  email, password = params[:email], params[:password]
  user = User.authenticate(email, password)
  if user
    session[:user_id] = user.id
    redirect to('/')
  else
    flash[:errors] = ["The email or password is incorrect"]
    erb :"sessions/new"
  end
end

delete '/sessions' do
  session[:user_id] = nil
  flash[:notice] = "Good bye!"
  redirect to('/')
end

get '/recover_password' do
  erb :recover_password
end

post '/recover_password' do
  user=User.first(:email=>params[:email])
  user.update_tokens
  send_simple_message(user)
  erb :update_password
end

def send_simple_message(user)
  RestClient.post "https://api:key-343493e3b4c83d0c3652b450171f6790"\
  "@api.mailgun.net/v2/sandbox083b2c50cc6a4e18bbd5173da7de219d.mailgun.org/messages",
  :from => "Mailgun Sandbox <postmaster@sandbox083b2c50cc6a4e18bbd5173da7de219d.mailgun.org>",
  :to => user.email,
  :subject => "Recover Password",
  :text => "http://localhost/9393/update_password/#{user.password_token}"
end

get'/update_password/:token' do
  @token=params[:token]
  erb :update_password
end

post '/update_password/' do
  user=User.first(:password_token => params[:token])
  password= params[:password]
  password_confirmation=params[:password_confirmation]
  user.update(:password => password,:password_confirmation=>password_confirmation, :password_token=> nil)
  erb :update_password
end



end






