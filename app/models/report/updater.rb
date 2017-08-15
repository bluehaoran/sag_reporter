require_relative "factory_floor"

class Report::Updater

  include Report::FactoryFloor

  attr_reader :instance
  attr_reader :error

  def initialize(report)
    @instance = report
  end

  def update_report(params)
    state_language_ids = params.delete 'languages'
    observers = params.delete 'observers_attributes'
    impact = params.delete 'impact_report'
    planning = params.delete 'planning_report'
    challenge = params.delete 'challenge_report'
    begin
      result = @instance.update_attributes(params)
      @instance.languages.clear
      add_languages(state_language_ids, @instance.geo_state_id) if state_language_ids
      @instance.topics.clear
      @instance.observers.clear
      add_observers(observers, @instance.geo_state_id, @instance.reporter) if observers

      if @instance.planning_report.present? and planning.to_i == 0
        @instance.planning_report.destroy
      end
      if @instance.impact_report.present? and impact.to_i == 0
        @instance.impact_report.destroy
      end
      if @instance.challenge_report.present? and challenge.to_i == 0
        @instance.challenge_report.destroy
      end

      if @instance.planning_report.blank? and planning.to_i == 1
        @instance.planning_report = PlanningReport.new
      end
      if @instance.impact_report.blank? and impact.to_i == 1
        @instance.impact_report = ImpactReport.new
      end
      if @instance.challenge_report.blank? and challenge.to_i == 1
        @instance.challenge_report = ChallengeReport.new
      end
      @instance.save!
    rescue => e
      Rails.logger.error(e.message)
      return false
    else
      return result
    end
  end

end