class ProjectsController < ApplicationController

  before_action :require_login

  before_action only: [:create, :destroy, :update] do
    head :forbidden unless logged_in_user.admin? or logged_in_user.zone_admin?
  end

  def index
    redirect_to root_path unless logged_in_user.admin?
    @projects = Project.all
  end

  def create
    @project = Project.create(project_params)
    respond_to :js
  end

  def destroy
    @project = Project.find(params[:id])
    if @project
      @project.destroy
      respond_to :js
    else
      head :not_found
    end
  end

  def edit
    @project = Project.find(params[:id])
    respond_to :js
  end

  def update
    @project = Project.find(params[:id])
    @project.update_attributes(project_params)
    respond_to :js
  end

  def show
    @project = Project.find(params[:id])
    respond_to :js
  end

  def add_language
    @project = Project.find(params[:id])
    @language = Language.find(params[:lang])
    #@language.project!
    @project.languages << @language unless @project.languages.include? @language
    respond_to :js
  end

  private

  def project_params
    params.require(:project).permit(:name)
  end

end
