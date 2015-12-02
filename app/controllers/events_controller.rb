class EventsController < ApplicationController

  before_action :require_login

  autocomplete :person, :name
  
  def new
  	@event = Event.new()
  	@minority_languages = Language.minorities(current_user.geo_states).order("LOWER(languages.name)")
  	@all_purposes = Purpose.all
  end

  def create
  	errors = Array.new
    @event = Event.new(event_params)
    @event.record_creator = current_user
    # link the languages to the event
    if params['event']['languages']
      params['event']['languages'].each do |lang_id, value|
        if value then @event.languages << Language.find(lang_id) end
      end
    end
    # link the purposes to the event
    if params['event']['purposes']
      params['event']['purposes'].each do |purp_id, value|
        if value then @event.purposes << Purpose.find(purp_id) end
      end
    end
    # link the people to the event
    person_params = params.select{ |param| param[/^person__\d+$/] }
    person_params.each do |key, person_name|
      unless person_name.empty?
        dude = Person.find_or_initialize_by(name: person_name)
        dude.record_creator ||= current_user
        dude.geo_state ||= GeoState.find(params['event']['geo_state_id'])
        dude.save
        @event.people << dude unless @event.people.include? dude
      end
    end
    if @event.save
      # create all the reports and link them to the event
      Event.yes_no_questions(current_user).each_key do |code|
      	if params[code] == 'yes'
      	  # collect the parameters for this report, and make the keys match.
      	  content = Hash[params.select{ |param| param[/^#{code}-response__\d+$/] }.map{ |k,v| [k.split('__').last,v] }]
      	  report_type = Hash[params.select{ |param| param[/^#{code}-type__\d+$/] }.map{ |k,v| [k.split('__').last,v] }]
      	  report_languages = Hash[params.select{ |param| param[/^#{code}-lang__\d+$/] }.map{ |k,v| [k.split('__').last,v] }]
      	  content.each do |key, value|
      	  	unless value.empty?
      	  	  report_params = {
      	  	    content: value,
      	  	  	reporter: current_user,
      	  	  	event: @event
      	  	  }
      	  	  unless code == 'plan' || code == 'impact' then report_params[code] = true end
      	  	  if report_type[key] == "impact"
      	  	    report = ImpactReport.create(report_params) or errors << "could not create impact report: " + value.slice(0..20)
      	  	  else
      	  	    report = Report.create(report_params) or errors << "could not create planning report: " + value.slice(0..20)
      	  	  end
              # link the languages to the report
              if report_languages[key] and report_languages[key]['languages'] and report_languages[key]['languages'].length > 0
                report_languages[key]['languages'].each do |lang_id, value|
                  if value then report.languages << Language.find(lang_id) end
                end
              else
                # if there are no languages specified for the report
                # then add the languages of the event
                if params['event']['languages']
                  params['event']['languages'].each do |lang_id, value|
                    if value then report.languages << Language.find(lang_id) end
                  end
                end
              end
      	  	end
      	  end
      	end
      end
      # Create the action points
      if params['decision'] == 'yes'
        action_content = Hash[params.select{ |param| param[/^decision-response__\d+$/] }.map{ |k,v| [k.split('__').last,v] }]
        action_person = Hash[params.select{ |param| param[/^person-responsible__\d+$/] }.map{ |k,v| [k.split('__').last,v] }]
        action_content.each do |key, value|
      	  unless value.empty?
      	  	person = Person.find_or_create_by(name: action_person[key])
      	  	action_params = {
      	      content: value,
      	  	  responsible: person,
      	  	  record_creator: current_user,
      	  	  event: @event
      	  	}
      	  	ActionPoint.create(action_params) or errors << "could not create action point: " + value.slice(0..20)
      	  end
      	end
      end

      # Save the event for good measure
      @event.save

      # show errors as a flash if any
      if !errors.empty?
      	flash['error'] = errors.join('<br/>'.html_safe)
      end
      redirect_to @event
    else
  	  @minority_languages = Language.minorities(current_user.geo_states).order("LOWER(languages.name)")
  	  @all_purposes = Purpose.all
  	  render 'new'
  	end

  end

  def show
  	@event = Event.find(params[:id])
  end

  private

    def event_params
      params.require('event').permit(
      	:event_label,
      	:district,
      	:sub_district,
      	:village,
      	:event_date,
      	:participant_amount,
      	:content,
        :geo_state_id
      	)
    end

end
