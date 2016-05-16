class ReportsController < ApplicationController

  helper ColoursHelper
  include ParamsHelper

  before_action :require_login

    # Let only permitted users do some things
  before_action only: [:new, :create] do
    redirect_to root_path unless logged_in_user.can_create_report?
  end

  before_action only: [:index, :by_language, :by_topic, :by_reporter] do
    redirect_to root_path unless logged_in_user.can_view_all_reports?
  end

  before_action only: [:show] do
  	# show shows single report only to reporter when report first created
  	redirect_to root_path unless logged_in_user?(Report.find(params[:id]).reporter) or logged_in_user.can_view_all_reports?
  end

  before_action only: [:edit, :update] do
    redirect_to root_path unless logged_in_user.can_edit_report? or logged_in_user?(Report.find(params[:id]).reporter)
  end

  before_action only: [:archive, :unarchive] do
    redirect_to root_path unless logged_in_user.can_archive_report?
  end

  before_action :get_translations, only: [:new, :edit]
  before_action :find_report, only: [:edit, :update, :show, :archive, :unarchive, :pictures]

  def new
  	@report = Report.new
    @report.pictures.build
  	@project_languages = StateLanguage.in_project.includes(:language, :geo_state).where(geo_state: logged_in_user.geo_states).order('languages.name')
    @topics = Topic.all
  end

  def create
    full_params = report_params.merge({reporter: logged_in_user})
    report_factory = Report::Factory.new
    if report_factory.create_report(full_params)
      flash['success'] = 'Report Submitted!'
      redirect_to report_factory.instance()
    else
      @report = report_factory.instance()
      flash['error'] = report_factory.error ? report_factory.error.message : 'Unable to submit report!'
      @project_languages = StateLanguage.in_project.includes(:language, :geo_state).where(geo_state: logged_in_user.geo_states).order('languages.name')
      @topics = Topic.all
      get_translations
      render 'new'
    end
  end

  def show
  end

  def edit
    @report.pictures.build
    @geo_states = @report.available_geo_states(logged_in_user)
    @project_languages = StateLanguage.in_project.includes(:language, :geo_state).where(geo_state: logged_in_user.geo_states).order('languages.name')
    @topics = Topic.all
  end

  def update
    updater = Report::Updater.new(@report)
  	if updater.update_report(report_params)
      flash['success'] = 'Report Updated!'
      redirect_to @report
    else
      if updater.error
        flash['error'] = "Report update failed: #{updater.error.message}"
      end
      @geo_states = @report.available_geo_states(logged_in_user)
      @project_languages = StateLanguage.in_project.includes(:language, :geo_state).where(geo_state: logged_in_user.geo_states)
      @topics = Topic.all
      get_translations
      render 'edit'
    end
  end

  def index
    @geo_states = logged_in_user.geo_states
    @zones = Zone.of_states(@geo_states)
    @languages = Language.minorities(@geo_states).order("LOWER(languages.name)")
    @reports = Report.includes(:languages, :reporter, :impact_report => [:progress_markers => :topic]).where(geo_state: @geo_states).order(:report_date => :desc).paginate(page: params[:page])
  end

  def by_language
    @geo_states = logged_in_user.geo_states
    @reports = Report.where(geo_state: @geo_states).order(:report_date => :desc)
    @impact_reports = ImpactReport.where(geo_state: @geo_states).order(:report_date => :desc)
    @languages = Language.all.order('LOWER(languages.name)')
    recent_view
  end

  def by_topic
    @geo_states = logged_in_user.geo_states
    @reports = Report.where(geo_state: @geo_states).order(:report_date => :desc)
    @impact_reports = ImpactReport.where(geo_state: @geo_states).order(:report_date => :desc)
    @topics = Topic.all
    recent_view
  end

  def by_reporter
    @geo_states = logged_in_user.geo_states
    @reports = Report.where(geo_state: @geo_states).order(:report_date => :desc)
    @impact_reports = ImpactReport.where(geo_state: @geo_states).order(:report_date => :desc)
    recent_view
  end

  def archive
    @report.archived!
    redirect_recent_or root_path
  end

  def unarchive
    @report.active!
    redirect_recent_or report
  end

  def pictures
    respond_to do |format|
      format.js
    end
  end

  def spreadsheet
    # The user can't see reports from geo_states they're not in
    # so take the intersection of the list of geo_states in the params
    # and the users geo_states
    if params['controls']['geo_state']
      geo_states = params['controls']['geo_state'].values.map{ |id| id.to_i } & logged_in_user.geo_states.pluck(:id)
    else
      geo_states = logged_in_user.geo_states
    end
    languages = params['controls']['language'].values.map{ |id| id.to_i }
    @reports = Report.includes(:languages).where('reports.geo_state_id' => geo_states, 'languages.id' => languages)

    if !params["show_archived"]
      @reports = @reports.active
    end

    start_date = params['from_date'].to_date
    end_date = params['to_date'].to_date
    @reports = @reports.select do |report|
      report.report_date >= start_date and report.report_date <= end_date
    end

    respond_to do |format|
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"impact-reports.csv\""
        headers['Content-Type'] ||= 'text/csv; charset=utf-8'
      end
    end
  end

  private

  def report_params
    # make hash options into arrays
    param_reduce(params['report'], ['topics', 'languages'])
    safe_params = [
      :content,
      :mt_society,
      :mt_church,
      :needs_society,
      :needs_church,
      :geo_state_id,
      :report_date,
      :planning_report,
      :impact_report,
      {:languages => []},
      {:topics => []},
      {:pictures_attributes => [:ref, :_destroy, :id]},
      {:observers_attributes => [:id, :name]},
      :status,
      :location,
      :sub_district_id
    ]
    safe_params.delete :status unless logged_in_user.can_archive_report?
    # if we have a date try to change it to db-friendly format
    # otherwise set it to nil
    if params[:report][:report_date]
      begin
        params[:report][:report_date] = DateParser.parse_to_db_str(params[:report][:report_date]) unless params[:report][:report_date].empty?
      rescue ArgumentError
        params[:report][:report_date] = nil
      end
    end
    permitted = params.require(:report).permit(safe_params)
  end

  def find_report
    @report = Report.find params[:id]
  end

  # Redirects to recent view (or to the default).
  def redirect_recent_or(default)
    redirect_to(session[:report_recent_view] || default)
    session.delete(:report_recent_view)
  end

  # Store which is the recent view in the session
  def recent_view
    session[:report_recent_view] = request.url if request.get?
  end

  def get_translations
    @translations = Hash.new
    if logged_in_user.interface_language
      lang_id = logged_in_user.interface_language.id
      Translatable.includes(:translations).find_each do |translatable|
        translation = translatable.translations.select{ |t| t.language_id == lang_id }.first
        content = (translation and translation.content) ? translation.content : translatable.content
        @translations[translatable.identifier] = content
      end
    else
      Translatable.find_each do |translatable|
        @translations[translatable.identifier] = translatable.content
      end
    end
  end

end
