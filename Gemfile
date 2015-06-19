if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

source 'http://rubygems.org'

gem 'rails', '= 3.2.19'
gem 'mysql2'
gem 'json'
gem 'haml'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2'
  gem 'coffee-rails', '~> 3.2'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery_datepicker'

# gem 'execjs'                                        # This requires a local (package) install of node.js
# gem 'therubyracer', :platform => :ruby               # This seems to be the only one feasible on the EC2 micro instance
gem 'therubyrhino', :platforms => :ruby
                                                    # [Steve, 20111216] Netzke:
gem 'netzke-core', '~> 0.7.7'           #, :git => "git://github.com/skozlov/netzke-core.git"
gem 'netzke-basepack', '~> 0.7.7'       #, :git => "git://github.com/skozlov/netzke-basepack.git"

gem 'i18n'                                          # [Steve, 20111216] Internationalization library

gem 'ruport', :git => 'https://github.com/ruport/ruport.git', :branch => 'ruby19-compat'
gem 'acts_as_reportable'
gem 'prawn', '~> 0.15'
                                                    # [Steve, 20130412] Custom Documatic version (used for Ooo exports):
gem 'documatic', :git => 'https://github.com/fasar-sw/documatic.git'
gem 'generator'
gem 'zip'
gem 'rubyzip', :require => 'zip/zip'

# [Steve, 20130801] Navigation gems for rendering menus & breadcrumbs:
gem "simple-navigation"
gem 'simple-navigation-bootstrap'

# To use uploads:
gem 'carrierwave'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'


group :development do
  gem "better_errors", '~> 1.1.0'
  gem "binding_of_caller"
  gem 'guard', '~> 2.6'
  gem 'guard-rspec'
  gem 'guard-shell'

  # Although Capistrano + seed_dump are strictly development-related gems,
  # including them into the test environment also allows Semaphore CI to
  # perform automated deployment from a test build without changing the current
  # Rails environment.
  gem 'capistrano',  '~> 3.4'                       # Deploy with Capistrano
  gem 'capistrano-rvm'
  gem 'capistrano-bundler' #, '~> 1.1.2'
  gem 'capistrano-rails' #, '~> 1.1'
  gem 'capistrano-passenger'
  gem 'net-ssh', '~> 2.9.2'
end


group :development, :test do
  gem "rspec", '~> 3'
  gem "rspec-rails", '~> 3'
  gem "factory_girl_rails"
  gem 'ffaker', '~> 2'                              # Adds dummy names & fixture generator
end

# To use debugger
#gem 'ruby-debug'
