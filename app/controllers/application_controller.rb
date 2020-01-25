class ApplicationController < ActionController::Base
    if Rails.env == "production" then
        before_action :basic

        private
        def basic
            authenticate_or_request_with_http_basic do |name, password|
            name == ENV['BASIC_AUTH_NAME'] && password == ENV['BASIC_AUTH_PASSWORD']
            end
        end
    end
end
