class ApplicationController < ActionController::Base
  before_action :authenticate_user
  skip_before_action :authenticate_user, only: [:create]


  def create
    resp = Faraday.get("https://foursquare.com/oauth2/access_token") do |req|
      req.params['client_id'] = ENV['FOURSQUARE_CLIENT_ID']
      req.params['client_secret'] = ENV['FOURSQUARE_SECRET']
      req.params['grant_type'] = 'authorization_code'
      req.params['redirect_uri'] = "http://localhost:3000/auth"
      req.params['code'] = params[:code]
    end

    body = JSON.parse(resp.body)
    session[:token] = body['access_token']
    redirect_to root_path
  end

  def friends
    resp = Faraday.get("https://api.foursquare.com/v2/users/self/friends") do |req|
      req.params['oauth_token'] = session[:token]
      # don't forget that pesky v param for versioning
      req.params['v'] = '20160201'
    end
    @friends = JSON.parse(resp.body)["response"]["friends"]["items"]
  end

  private
  
    def authenticate_user
      client_id = ENV['FOURSQUARE_CLIENT_ID']
      redirect_uri = CGI.escape("http://localhost:3000/auth")
      foursquare_url = "https://foursquare.com/oauth2/authenticate?client_id=#{client_id}&response_type=code&redirect_uri=#{redirect_uri}"
      redirect_to foursquare_url unless logged_in?
    end
  
    def logged_in?
      !!session[:token]
    end
end
