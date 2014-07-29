require 'sinatra'
require 'data_mapper'
require 'rack-flash'


env = ENV["RACK_ENV"] || "development"
DataMapper.setup(:default, "postgres://localhost/bookmark_manager_#{env}")
require './lib/link' 
require './lib/tag'
require './lib/user'

DataMapper.finalize
DataMapper.auto_upgrade!


class Bookmark < Sinatra::Base	
	enable :sessions
	set :session_secret, 'super secret'
  use Rack::Flash
	get '/' do 
		@links = Link.all
  	erb :index
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
	
# 	post '/users' do
#   user = User.create(:email => params[:email], 
#               :password => params[:password])
#   session[:user_id] = user.id
#   redirect to('/')
# end

post '/users' do
  @user=user = User.create(:email => params[:email], 
              :password => params[:password],
              :password_confirmation => params[:password_confirmation])  
if @user.save
  session[:user_id] = @user.id
  redirect to('/')
 else
    flash[:notice] = "Sorry, your passwords don't match"
    erb :"users/new"
  end
end

helpers do

  def current_user    
    @current_user ||=User.get(session[:user_id]) if session[:user_id]
  end

end




end

