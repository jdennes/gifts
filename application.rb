require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'environment'
require 'pony'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"

  enable :sessions
end

helpers do
  def needs_auth
      raise not_found unless has_auth?
  end

  def has_auth?
      session[:authorised] == true
  end
  
  def build_finalise_email(gift)
    "Hey #{gift.intention.name}\r\n\r\nThanks for confirming your intention to purchase the \"#{gift.name}\". \
To finalise your intention, you need to click the link below, or copy and paste it into your browser:\r\n\r\n\
http://gifts.johnandsal.com/gift/#{gift.id}/finalise/#{gift.intention.token} \r\n\r\n\
Thank you once again!"
  end

  def get_categories
    { "bathroom" => "Bathroom", "bedroom" => "Bedroom", "kitchen" => "Kitchen", "laundry" => 
      "Laundry", "livingroom" => "Living Room", "outdoor" => "Outdoor" }
  end
end

error do
    haml :error
end

not_found do
    haml :not_found
end

get '/login/?' do
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    unless @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials[0] == SiteConfig.admin_username && 
      OpenSSL::Digest::SHA1.new(@auth.credentials[1]).hexdigest == SiteConfig.admin_password
        response['WWW-Authenticate'] = %(Basic realm="gifts")
        throw :halt, [401, "Sorry, you're not allowed here. :)"]
        return
    end
    
    session[:authorised] = true
    redirect '/'
end

get '/logout/?' do
    session[:authorised] = false
    redirect '/'
end

get '/gift/new/?' do
  needs_auth

  @gift = Gift.new(params)
  @categories = get_categories
  haml :gift_form
end

post '/gift/new/?' do
  needs_auth

  @gift = Gift.new(
    :name => params["name"],
    :description => params["description"],
    :category => params['category'],
    :status => 'available'
  )

  if @gift.save
    redirect "/"
  else
    @categories = get_categories
    haml :gift_form
  end
end

get '/gift/:id/edit/?' do |id|
  needs_auth
  @gift = Gift.first(:id => id)
  raise not_found unless @gift
  @categories = get_categories
  haml :gift_form
end

post '/gift/:id/edit/?' do |id|
  needs_auth
  @gift = Gift.first(:id => id)
  raise not_found unless @gift

  @gift.attributes = {
    :name => params["name"],
    :description => params["description"],
    :category => params['category'],
    :status => params["status"]
  }

  if @gift.status == 'available' and @gift.intention
    # Ensure that intention is destroyed if it was set
    @gift.intention.destroy
  end

  if @gift.save
    redirect '/'
  else
    @categories = get_categories
    haml :gift_form
  end
end

get '/gift/:id/delete/?' do |id|
  needs_auth
  @gift = Gift.first(:id => id)
  raise not_found unless @gift
  haml :delete_gift
end

post '/gift/:id/delete/?' do |id|
  needs_auth
  @gift = Gift.first(:id => id)
  raise not_found unless @gift
  @gift.destroy
  redirect '/'
end

get '/' do
  
  require 'pp'
  
  @all_gifts = Gift.all(:status => 'available')
  @gifts_by_cat = {}
  @categories = get_categories
  @categories.each do |k, v|
    @all_gifts.each do |g|
      if g.category == k
        if !@gifts_by_cat[k]
          @gifts_by_cat[k] = []
        end
        @gifts_by_cat[k] << g
      end
    end
  end

  pp @categories
  pp @gifts_by_cat
  
  haml :index
end

get '/gift/:id/?' do |id|
  @gift = Gift.first(:id => id)
  raise not_found unless @gift
  @intention = Intention.new(params)
  haml :gift
end

post '/gift/:id/confirm/?' do |id|
  @gift = Gift.first(:id => id)
  raise not_found unless @gift
  
  @gift.status = 'confirmed'
  @token = OpenSSL::Digest::SHA1.new(
    "#{Time.new}%@*&^!-09#{@gift.id}").hexdigest
  @intention = Intention.new(
    :name => params["name"],
    :email => params['email'],
    :token => @token
  )
  @gift.intention = @intention
  if @gift.save
    Pony.mail :to => @gift.intention.email,
              :from => "gifts@johnandsal.com",
              :subject => "Please finalise your intention to purchase: #{@gift.name}",
              :body => build_finalise_email(@gift)
    haml :finalise_gift
  else
    haml :gift
  end
end

get '/gift/:id/finalise/:token/?' do |id, token|
  @gift = Gift.first(:id => id)
  raise not_found unless (@gift and @gift.status == 'confirmed' and @gift.intention.token == token)
  @gift.status = 'finalised'
  @gift.save

  haml :gift_finalised
end

get '/confirmed' do
  needs_auth
  @confirmed = Gift.all(:status => 'confirmed')
  haml :confirmed
end

get '/finalised' do
  needs_auth
  @finalised = Gift.all(:status => 'finalised')
  haml :finalised
end
