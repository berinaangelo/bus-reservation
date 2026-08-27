class ApplicationController < ActionController::API
  include Pundit::Authorization
  include Pagy::Method
end
