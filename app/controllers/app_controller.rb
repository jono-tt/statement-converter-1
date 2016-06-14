class AppController < ApplicationController
  prepend_before_filter :http_basic_auth if ["production"].include?(Rails.env)

  def http_basic_auth
    authenticate_or_request_with_http_basic('Administration') do |username, password|
      username == 'login' && password == 'f0rg0t'
    end
  end
end
