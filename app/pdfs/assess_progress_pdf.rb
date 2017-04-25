require 'open-uri'

class AssessProgressPdf < Prawn::Document

  def initialize(state_language, months, user, reports)
    super(page_layout: :portrait)
    @state_language = state_language
    @months = months
    @user = user
    @reports = reports
    header
    content
  end

  def header
    text "Assess the outcome progress for #{@state_language.language_name} in #{@state_language.state_name} over the last #{@months} months", size: 18, style: :bold
  end

  def content
    Topic.all.order(:number).each do |outcome_area|
      pad_top(10) { text outcome_area.name, size: 16, style: :bold }
      outcome_area.progress_markers.active.order(:number).each do |pm|
        bounding_box([0, cursor], width: 500) do
          pad(5) { text "#{pm.number}. #{pm.description_for(@user)}" }
          stroke_bounds
        end
        if @reports[pm] and @reports[pm].any?
          print_reports(@reports[pm])
        else
          pad(5) { text 'no impact reports for this progress marker' }
        end
      end
    end
  end

  def print_reports(reports)
    reports.each do |report|
      pad_top(5) { text report.report_date.to_s, style: :bold }
      text report.content
      report.pictures.each do |picture|
        if Rails.env.production?
          image open(picture.ref_url), fit: [500,500] if picture.ref?
        else
          image "#{Rails.root}/public#{picture.ref_url}", fit: [500,500] if picture.ref?
        end
      end
    end
  end

end