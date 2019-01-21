source 'https://rubygems.org'
ruby "~> 2.5.1"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.10'
# Use SCSS for stylesheets
gem 'sassc-rails'
# Use Materialize for Google's Material Design layout
gem 'materialize-sass'

# Use Google's Material Design Lite for Google's Material Design UX
gem 'material_design_lite-sass'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Also we need jQuery-UI for autocomplete on fields
gem 'jquery-ui-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
#gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Populate db with multiple entities
gem 'faker'

# Pagination helper
gem 'will_paginate', '~> 3.0.6'

# group dates by periods
gem 'groupdate'

# create charts
gem 'chartkick', '~> 1.3.2'

# autocomplete in text fields
gem 'rails4-autocomplete'

# Use PostgreSQL as the database for Active Record
gem 'pg', '~> 0.20.0'

# Output PDF files
gem 'prawn'
gem 'prawn-table'
gem 'prawn-graph'

# Output excel files
gem 'rubyzip', '~> 1.1.0'
gem 'axlsx', '2.1.0.pre'
gem 'axlsx_rails'

# Custom icon fonts
gem 'fontcustom'

# File upload
gem 'carrierwave'

# JWT for android-app authentication
gem 'jwt'

# dates and times used for datepicker
gem 'momentjs-rails', '~> 2.11', '>= 2.11.1'

# image manipulation
gem 'mini_magick'

# simplify http requests
gem 'httparty'
gem 'active_model_otp'
gem 'sendgrid_actionmailer_adapter'
gem 'recaptcha', require: 'recaptcha/rails'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # For creating test-doubles
  gem 'mocha', require: false

  # Factories instead of fixures
  gem 'factory_bot_rails'

  # For high level specification of integration tests
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'

  # for managing environment variable
  gem 'dotenv-rails'
end

group :development do

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

end

group :test do
  # For colouring test results red and green
  gem 'minitest-reporters'

  # For stopping test backtraces reaching beyound my own code
  #gem 'mini_backtrace'

  # Capybara lets us simulate users interacting with the interface
  gem 'minitest-rails-capybara'

  # For more readable test code using spec syntax
  gem 'minitest-spec-rails'

  # Spec syntax with Capybara
  gem 'capybara_minitest_spec', '1.0.6'

  # Open browser on page that is being tested whe test fails.
  gem 'launchy'

  # Drives a web browser for testing
  #gem 'selenium-webdriver' #depends on an insecure version of rubyzip

  # Drives a headless browser (phantom js)
  # gem 'poltergeist'
  # gem 'phantomjs', require: 'phantomjs/poltergeist'

  # for js testing in capybara and cucumber
  #gem 'capybara-webkit'

  # code coverage for tests
  gem 'simplecov', require: false

end

group :production do

  # used by Heroku to serve static assets
  gem 'rails_12factor'

  # Puma is a production server
  gem 'puma'

  # enable rolling restart
  gem 'puma_worker_killer'

  # link to cloud storage
  gem 'fog-google'

end

