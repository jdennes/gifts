require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'environment'

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
  @all_gifts = Gift.all(:status => 'available', :order => [ :name.asc ])
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
  
  @intention = Intention.new(
    :name => params["name"],
    :email => params['email'],
    :created_at => Time.now.utc
  )
  if @intention.valid?
    @gift.status = 'confirmed'
    @gift.intention = @intention
    if @gift.save
      haml :gift_confirmed
    else
      haml :gift
    end
  else
    haml :gift
  end
end

get '/confirmed' do
  needs_auth
  @confirmed = Gift.all(:status => 'confirmed', :order => [ :name.asc ])
  haml :confirmed
end