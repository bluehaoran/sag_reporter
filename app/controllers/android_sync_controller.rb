class AndroidSyncController < ApplicationController

  include JwtConcern
  include ParamsHelper

  skip_before_action :verify_authenticity_token
  before_action :authenticate_external

  def send_request
    tables = {
        User => %w(name user_type),
        GeoState => %w(name zone_id),
        Language => %w(name colour),
        Person => %w(name geo_state_id),
        Topic => %w(name colour),
        ProgressMarker => %w(name topic_id),
        Zone => %w(name),
        Report => %w(reporter_id content geo_state_id report_date impact_report_id status client version significant project_id church_ministry_id),
        ImpactReport => %w(translation_impact),
        UploadedFile => %w(report_id),
        MtResource => %w(user_id name language_id cc_share_alike medium status geo_state_id url),
        Organisation => %w(name abbreviation church),
        LanguageProgress => %w(progress_marker_id state_language_id),
        ProgressUpdate => %w(user_id language_progress_id progress month year),
        StateLanguage => %w(geo_state_id language_id project),
        ChurchTeam => %w(name organisation_id village geo_state_id),
        ChurchMinistry => %w(church_team_id ministry_id language_id status facilitator_id),
        Ministry => %w(number topic_id),
        Deliverable => %w(number ministry_id for_facilitator),
        MinistryOutput => %w(deliverable_id month value actual church_ministry_id creator_id comment),
        ProductCategory => %w(number),
        Project => %w(name),
        ProjectStream => %w(project_id ministry_id supervisor_id),
        Facilitator => %w(user_id),
        FacilitatorFeedback => %w(church_ministry_id month feedback team_member_id response)
    }
    join_tables = {
        User: %w(geo_states spoken_languages church_teams),
        Report: %w(languages observers),
        ImpactReport: %w(progress_markers),
        ChurchTeam: %w(users),
        Project: %w(languages project_users),
        Facilitator: %w(languages ministries),
        MtResource: %w(product_categories)
    }
    @all_restricted_ids = Hash.new
    def restrict(table)
      restricted_ids = table.ids
      unless @external_user.national
        user_geo_states = @external_user.geo_state_ids
        restricted_ids = case table.new
          when User
            table.joins(:geo_states).where(geo_states: {id: user_geo_states}).ids
          when Language
            table.joins(:geo_states).where(geo_states: {id: user_geo_states}).ids
          when Person
            table.where(geo_state_id: user_geo_states).ids
          when MtResource
            table.where(geo_state_id: user_geo_states).ids
          when ChurchTeam
            table.where(geo_state_id: user_geo_states).ids
          when Report
            table.where(geo_state_id: user_geo_states).ids
          when LanguageProgress
            table.joins(:state_language).where(state_languages: {geo_state_id: [user_geo_states]}).ids
            
          when ImpactReport
            table.joins(:report).where(reports:{id: @all_restricted_ids[Report.name]}).ids
          when ProgressUpdate
            table.where(language_progress_id: @all_restricted_ids[LanguageProgress.name]).ids
          when ChurchMinistry
            table.where(church_team_id: @all_restricted_ids[ChurchTeam.name]).ids
          when MinistryOutput
            table.where(church_ministry_id: @all_restricted_ids[ChurchMinistry.name]).ids
          when FacilitatorFeedback
            table.where(church_ministry_id: @all_restricted_ids[ChurchMinistry.name]).ids
          when Project
            table.joins(:languages).where(languages: {id: @all_restricted_ids[Language.name]}).ids
          when Facilitator
            table.where(user_id: @all_restricted_ids[User.name]).ids
          else restricted_ids
        end
      end
      unless @external_user.trusted
        restricted_ids = case table.new
          when User
            [@external_user.id]
          when Organisation
            []
          when Report
            table.where(id: restricted_ids, reporter_id: @external_user.id).ids
            
          when Facilitator
            table.where(user_id: @all_restricted_ids[User.name]).ids
          when ImpactReport
            table.joins(:report).where(reports:{id: @all_restricted_ids[Report.name]}).ids
          else
            restricted_ids
        end
      end
      #just send pictures, which have a valid report_id
      if table == UploadedFile
        restricted_ids = table.where(report_id: @all_restricted_ids[Report.name]).ids
      end
      @all_restricted_ids[table.name] = restricted_ids
    end
    def additional_tables(entry)
      case entry
        when ProgressMarker
          {description: entry.description_for(@external_user)}
        when ProgressUpdate
          {month: "#{entry.year}-#{'%02i' % entry.month}"}
        when StateLanguage
          {is_primary: entry.primary}
        else
          {}
      end
    end
    
    safe_params = [
        :last_sync
    ] + tables.map{|table, _| {table.name => []} }
    send_request_params = params.require(:external_device).permit(safe_params)
    
    @final_file = Tempfile.new
    render json: {data: "#{@final_file.path}.txt"}, status: :ok
    Thread.new do
      begin
        File.open(@final_file, "w") do |file|
          last_sync = Time.at send_request_params["last_sync"]
          this_sync = 5.seconds.ago
          file.write "{\"last_sync\":#{this_sync.to_i}"
          raise "No last sync variable" unless send_request_params["last_sync"]
          tables.each do |table, attributes|
            table_name = table.name.to_sym
            offline_ids = send_request_params[table.name] || [0]
            has_entry = false
            restricted_ids = restrict(table)
            table.where("updated_at BETWEEN ? AND ? AND id IN (?) OR id IN (?)",
                        last_sync, this_sync, restricted_ids & offline_ids, restricted_ids - offline_ids)
                .includes(join_tables[table_name]).each do |entry|
              entry_data = Hash.new
              (attributes + ["id"]).each do |attribute|
                entry_data.merge!({attribute => entry.send(attribute)})
              end
              join_tables[table_name]&.each do |join_table|
                entry_data.merge!({join_table => entry.send(join_table.singularize.foreign_key.pluralize)})
              end
              begin
                entry_data.merge! additional_tables(entry)
              rescue => e
                logger.error "Error in adding additional tables for #{entry.class}: #{entry.attributes}" + e.to_s
              end
              if has_entry
                file.write(",")
              else
                file.write(",")
                file.write "\"#{table_name}\":["
              end
              has_entry = true
              file.write entry_data.to_json
            end
            file.write "]" if has_entry
            ActiveRecord::Base.connection.query_cache.clear
          end
          file.write "}"
        end
      rescue => e
        send_message = {error: e.to_s, where: e.backtrace.to_s}.to_json
        logger.error send_message
        file_path = @final_file.path
        @final_file.delete
        @final_file = File.new file_path, "w"
        @final_file.write send_message
      ensure
        @final_file.close unless @final_file.closed?
        logger.debug "File writing finished"
        File.rename(@final_file, "#{@final_file.path}.txt")
        ActiveRecord::Base.connection.close
      end
    end
  end

  def get_file
    begin
      safe_params = [
          :file_path
      ]
      get_file_params = params.require(:external_device).permit(safe_params)

      file_path = get_file_params["file_path"]
      deadline = Time.now + 1.minute
      until File.exists?(file_path)
        sleep 1
        raise "Creating of the file took to long" if Time.now > deadline
      end
      send_file file_path, status: :ok
    rescue => e
      send_message = {error: e.to_s, where: e.backtrace.to_s}.to_json
      logger.error send_message
      render json: send_message, status: :internal_server_error
    end
  end

  def get_uploaded_file
    safe_params = [
        uploaded_files: [],
    ]
    get_uploaded_file_params = params.require(:external_device).permit(safe_params)

    @all_data = Tempfile.new
    render json: {data: "#{@all_data.path}.txt"}, status: :ok
    Thread.new do
      begin
        uploaded_file_ids = get_uploaded_file_params["uploaded_files"].map {|key, _| key.to_i}
        pictures_data, errors = Array.new(2) {Tempfile.new}
        UploadedFile.includes(:report).find(uploaded_file_ids).each do |uploaded_file|
          image_data = if uploaded_file&.ref.file.exists?
                         Base64.encode64(uploaded_file.ref.read)
                       else
                         ""
                       end
          if external_user.trusted? || uploaded_file.report.reporter == external_user
            pictures_data.write(", ") unless pictures_data.length == 0
            pictures_data.write({
                                    id: uploaded_file.id,
                                    data: image_data
                                }.to_json)
          else
            errors << {"uploaded_file:#{uploaded_file.id}" => "permission denied"}
          end
        end
        send_message = { UploadedFile: pictures_data }
        send_message.merge!({ errors: errors}) unless errors.size == 0
        save_data_in_file send_message
      rescue => e
        send_message = {error: e.to_s, where: e.backtrace.to_s}.to_json
        logger.error send_message
        @all_data.write send_message
      ensure
        [@all_data, pictures_data, errors].each &:close
        File.rename(@all_data, "#{@all_data.path}.txt")
        [pictures_data, errors].each &:delete
      end
    end
  end

  def receive_request
    begin
      @foreign_key_names = {
          picture: :uploaded_file,
          reporter: :user,
          observer: :person,
      }
      safe_params = [
          :is_only_test,
          person: [
              :old_id,
              :name,
              :user_id,
              :geo_state_id

          ],
          report: [
              :id,
              :old_id,
              :geo_state_id,
              {language_ids: []},
              :language_ids,
              :report_date,
              :translation_impact,
              :significant,
              :content,
              :reporter_id,
              :impact_report,
              {progress_marker_ids: []},
              :progress_marker_ids,
              {observer_ids: []},
              :observer_ids,
              :client,
              :version,
          ],
          uploaded_file: [
              :old_id,
              :data,
              :report_id
          ],
          impact_report: [
                  :id,
                  :old_id,
                  :report_id,
                  :shareable,
                  :translation_impact
          ],
          church_team: [
              :id,
              :old_id,
              {user_ids: []},
              :user_ids,
              :organisation_id,
              :village,
              :geo_state_id
          ],
          church_ministry: [
              :id,
              :old_id,
              :church_team_id,
              :ministry_id,
              :status,
              :facilitator_id,
              :language_id
          ],
          ministry_output: [
              :id,
              :old_id,
              :church_ministry_id,
              :deliverable_id,
              :month,
              :creator,
              :value,
              :comment,
              :actual
          ]
      ]
      receive_request_params = params.deep_transform_keys!(&:underscore).require(:external_device).permit(safe_params)

      @is_only_test = receive_request_params["is_only_test"]
      @errors = []
      @id_changes = {}

      # The following tables have to be in the order, that they only contain IDs of the previous ones
      [Person, Report, ImpactReport, UploadedFile, ChurchTeam, ChurchMinistry, MinistryOutput].each do |table|
        receive_request_params[table.name.underscore]&.each {|entry| build table, entry.to_h}
      end
      puts @id_changes
      @id_changes.each do |table, entries|
        entries.each do |old_id, new_entry|
          begin
            if @is_only_test
              @errors << {"#{table}:#{old_id}" => new_entry.errors.messages.to_s} unless new_entry&.valid?
            else
              @errors << {"#{table}:#{old_id}" => new_entry.errors.messages.to_s} unless new_entry&.save
            end
          rescue => e
            @errors << {"#{table}:#{old_id}" => e.message}
          end
        end
      end
      # Send back all the ID changes (as only the whole entries were saved, the ID has to be retrieved here)
      if @is_only_test
        send_message = @id_changes.map{|k,v| [k, v.map{|k2,v2| [k2, v2.valid?] }.to_h] }.to_h
      else
        send_message = @id_changes.map{|k,v| [k, v.map{|k2,v2| [k2, v2.id] }.to_h] }.to_h
      end
      send_message.merge!({error: @errors}) unless @errors.empty?
      logger.debug send_message
      render json: send_message, status: :created
    rescue => e
      send_message = {error: e.to_s, where: e.backtrace.to_s}.to_json
      logger.error send_message
      render json: send_message, status: :internal_server_error
    end
  end

  private

  # receive_request methods:

  def build(table, hash)
    old_id = nil
    begin
      if table == Report && hash["reporter_id"] != @external_user && !@external_user.admin
        Report.find(hash["id"]).touch if hash["id"]
        raise "User is not allowed to edit report #{hash["id"]}"
      elsif table == UploadedFile
        filename = "external_uploaded_image"
        @tempfile = Tempfile.new filename
        @tempfile.binmode
        @tempfile.write Base64.decode64 hash.delete("data")
        @tempfile.rewind
        content_type = `file --mime -b #{@tempfile.path}`.split(";")[0]
        extension = content_type.match(/gif|jpg|jpeg|png/).to_s
        filename += ".#{extension}" if extension
        hash["ref"] = ActionDispatch::Http::UploadedFile
                            .new({
                                     tempfile: @tempfile,
                                     type: content_type,
                                     filename: filename
                                 })
      end
      # Go through all the entries to check, whether it has an ID from another uploaded entry
      hash.clone.each do |k, v|
        if k.last(4) == "_ids" && v.is_a?(Array)
          foreign_table = k.remove("_ids")
          foreign_table = @foreign_key_names[foreign_table .to_sym]&.to_s || foreign_table
          foreign_table = foreign_table.camelcase
          hash[k.remove("_ids").pluralize] = v.map do |element|
            @id_changes.dig(foreign_table, element) || foreign_table.constantize.find(element)
          end
          hash.delete k
        elsif k.last(3) == "_id" && k != "old_id"
          foreign_table = k.remove("_id")
          foreign_table = @foreign_key_names[foreign_table.to_sym]&.to_s || foreign_table
          foreign_table = foreign_table.camelcase
          hash[k.remove("_id")] = @id_changes.dig(foreign_table, v) || foreign_table.constantize.find(v)
          hash.delete k
        elsif v == nil && k.last(4) == "_ids"
          hash[k] = []
        end
      end
      logger.debug "#{table}: #{hash}"
      @id_changes[table.name] ||= {}
      if (id = hash["id"])
        entry = @is_only_test? table.find(id) : table.update(id, hash)
        @id_changes[table.name].merge!({old_id => entry})
      elsif (old_id = hash.delete "old_id")
        new_entry = table.new hash
        @id_changes[table.name].merge!({old_id => new_entry})
      else
        raise "Entry needs either an ID value or an 'old ID' value"
      end
    rescue => e
      @errors << {"#{table}:#{old_id}" => e.message}
    ensure
      if @tempfile
        @tempfile.close
        @tempfile.unlink
      end
    end
  end

  def save_data_in_file(send_message)
    File.open(@all_data, "w") do |final_file|
      final_file.write "{"
      send_message.each_with_index do |pair, index|
        category, file = pair
        file.close
        file.open
        final_file.write ", " unless index == 0
        final_file.write "\"#{category}\": ["
        final_file.write file.read
        final_file.write "]"
        file.close
        file.unlink
      end
      final_file.write "}"
    end
    @all_data.close
  end
  # other helpful methods
  
  def authenticate_external
    render json: { error: "JWT invalid", user: @jwt_user_id }, status: :unauthorized unless external_user
  end

  def external_user
    @external_user ||= begin
      token = request.headers["Authorization"].split.last
      payload = decode_jwt(token)
      @jwt_user_id = payload["sub"]
      user = User.find_by_id @jwt_user_id
      users_device = ExternalDevice.find_by device_id: payload["iss"], user_id: @jwt_user_id
      if user.updated_at.to_i == payload["iat"]
        user if users_device
      else
        users_device.update registered: false if users_device&.registered
        false
      end
    rescue => e
      logger.error e
      nil
    end
  end

end
# for easily getting all attributes:
# Language.new.attributes.except("created_at","updated_at").keys.each{|k|puts "          #{k}: xxx.#{k},"}.nil?
# puts tables.map{|t|  "["+t.name + ", %w(" +t.new&.attributes&.except("created_at", "updated_at", "id")&.keys&.join(" ").to_s + ")],"}

# hm=Person.reflect_on_all_associations(:has_many).map{|r|r.name}
# hm2=hm.map{|h|h.to_s.singularize + "_ids"}
# Person.includes(hm).map{|p| hm2.map{|h|[h,p.send(h)]}.to_h.merge(p.attributes.except("created_at", "updated_at"))}

# Language.reflect_on_all_associations(:has_many).map{|a|[a.name,a.options[:through],a.options[:source]]}
# => [[:geo_states, :state_languages, nil],...]
# Language.includes(a.options[:through]).map {|l|l.send(a.options[:through]).map &a.options[:source] || a.name}

# def r t;t.reflect_on_all_associations(:has_many).map {|a|puts [a.name.to_s.singularize.to_sym, a.options[:through], a.options[:source]].to_s};t.reflect_on_all_associations(:has_and_belongs_to_many).map {|a|puts [a.name.to_s.singularize.to_sym, a.options[:through], a.options[:source]].to_s}.nil?; end