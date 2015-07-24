class LanguagesController < ApplicationController
  
  helper ColoursHelper

  before_action :require_login

    # Let only permitted users do some things
  before_action only: [:new, :create] do
    redirect_to root_path unless current_user.can_create_language?
  end

  before_action only: [:index] do
    redirect_to root_path unless current_user.can_view_all_languages?
  end

  before_action only: [:edit, :update] do
    redirect_to root_path unless current_user.can_edit_language?
  end

  def index
  	@languages = Language.order("LOWER(name)")
  end

  def new
  	@language = Language.new
  	@colour_columns = 3
  end

  def edit
  	@language = Language.find(params[:id])
  	@colour_columns = 3
  end

  def show
  	@language = Language.find(params[:id])
  end

  def update
    @language = Language.find(params[:id])
    if @language.update_attributes(combine_colour(lang_params))
      flash["success"] = "Language updated"
      redirect_to @language
    else
      render 'edit'
    end
  end

  def create
    @language = Language.new(combine_colour(lang_params))
    if @language.save
      flash["success"] = "New language added!"
      redirect_to @language
    else
      render 'new'
    end
  end

    private

    def lang_params
      params.require(:language).permit(:name, :description, :lwc, :colour, :colour_darkness)
    end
  
end