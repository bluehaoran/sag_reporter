# Parse fixture files to seed the database in a non-destructive way
# duplicates are avoided and you may specify if the fields of an
# existing record should be updated.


module FixtureParser

  require 'yaml'

  # files_options_hash has fixtures file names as keys and then a hash like this as values
  # {
  #  model_name: 'Permission',
  #  key_field: 'name' # this field defines the record - if it's the same it should be the same record
  #  update?: true # perform an update on existing records or only add new ones
  # }

  def parse_fixtures(files_options_hash)

  	# load the data from the files
  	fixtures = Hash.new
  	files_options_hash.each_key do |filename|
  	  fixtures[filename] = YAML.load(ERB.new(File.read(filename)).result)
  	end

  	# before updating collect all the objects by names given in fixtures
  	all_objects = Hash.new
  	# and remember which need to be updated with their hash
  	to_update = Hash.new

  	# for each fixture file
  	fixtures.each do |filename, fixtures_hash|
      puts "processing #{filename}"
  	  model_class = files_options_hash[filename][:model_name].classify.constantize
  	  key_fields = files_options_hash[filename][:key_fields]

  	  #for each fixture within the file
  	  fixtures_hash.each do |fixture, values_hash|
  	  	if files_options_hash[filename][:update?]
          puts fixture
  	  	  # if we doing updates get or initialise it and apply the values then save
          if key_fields
            key_hash = values_hash.dup.keep_if{ |k, v| key_fields.include? k }
            key_hash.update(key_hash){ |k, v| all_objects[v] || v }
  	  	    model_instance = model_class.find_or_initialize_by(key_hash)
          else
            model_instance = model_class.new
          end
  	  	  all_objects[fixture] = model_instance
  	  	  to_update[fixture] = values_hash
  	  	else
  	  	  # if we're not updating check if it's there and add it if it's not
          if key_fields
            key_hash = values_hash.dup.keep_if{ |k, v| key_fields.include? k }
            key_hash.update(key_hash){ |k, v| all_objects[v] || v }
  	  	    model_instance = model_class.find_by(key_hash)
          end
  	  	  if !model_instance
  	  	  	model_instance = model_class.new
  	  	  	to_update[fixture] = values_hash
  	  	  end
  	  	  all_objects[fixture] = model_instance
          if model_instance.respond_to? "name"
            puts "#{fixture}: #{model_instance.name}"
          else
            puts "#{fixture}: #{model_instance}"
          end
  	  	end
  	  end
  	end

  	# now we've collected all the models we can update the ones that need updating
  	to_update.each do |fixture_name, values_hash|
  	  update_model_instance(all_objects[fixture_name], values_hash, all_objects.except(fixture_name))
  	end

  end

  # Update a model instance with values from a fixture.
  # Some values may refer to other fixtures
  def update_model_instance(model_instance, values_hash, all_fixture_instances)
    if model_instance.respond_to? "name"
      puts "updating #{model_instance.name}"
    else
      puts "updating #{model_instance}"
    end

  	values_hash.each do |field, value|
  	  # if the field is an array we need to assign with 'push' instead of '='
  	  if model_instance.send(field).respond_to?("push")
  	  	model_instance.send(field).clear
  	  	push = true
  	  end
      # it may be a comma seperated list of fixtures so process it
      values_array = replace_strings_with_fixtures(value, all_fixture_instances)
      values_array.each do |value|
        if value.respond_to? "name"
          puts "  #{field}: #{value.name}"
        else
          puts "  #{field}: #{value}"
        end
  	    if push
  	      model_instance.send(field).push(value)
  	    else
  	      model_instance.send(field + '=', value)
  	    end
  	  end
  	end

    begin
      if model_instance.valid?
    	  model_instance.save!
      else
        puts "*** not valid: #{model_instance}"
        puts model_instance.errors
      end

    rescue PG::UniqueViolation
      puts "*** not unique: #{model_instance}"
    end

  end

  def replace_strings_with_fixtures(value, all_fixture_instances)
  	if value.respond_to?("split")
  	  # it might be a comma sperated list of fixtures
  	  fixtures_array = value.split(',').map(&:strip)
  	  fixtures_array.each_with_index do |fixture_name, index|
  	  	if obj = all_fixture_instances[fixture_name]
  	  	  fixtures_array[index] = obj
				else
  	  	  # could not find one fixture
  	  	  # it must just be a string after all
  	  	  return [value]
  	  	end
  	  end
  	  return fixtures_array
  	end
  	# it's not a string, return it in it's own array
  	return [value]
  end

end