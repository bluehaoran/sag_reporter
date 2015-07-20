class ApplicationController < ActionController::Base

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Access sessions helper and roles helper from application controllers.
  include SessionsHelper
  include RolesHelper

  private

    def combine_colour(params)
      unless params[:colour] == "black" or params[:colour] == "white"
        if params[:colour_darkness].to_i > 0
      	  params[:colour] << " darken-" << params[:colour_darkness]
        elsif params[:colour_darkness].to_i < 0
      	  params[:colour] << " lighten-" << params[:colour_darkness].slice(1..-1)
        end
      end
      params.except!(:colour_darkness)
    end

end
