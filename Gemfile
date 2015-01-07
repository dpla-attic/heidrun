source 'https://rubygems.org'

gem 'rails', '4.1.6'

gem 'krikri', github: 'dpla/krikri', branch: 'fix-jettywrapper-in-host'

gem 'sqlite3'
gem 'sass-rails', '~> 4.0.3'

# Gems used only for assets; not required by rails
# in production environments.
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'therubyracer',  platforms: :ruby

gem 'jquery-rails'
gem 'jquery-ui-rails'

group :development do
  gem 'spring'
  gem 'guard', '~>1.0'
  gem 'guard-rspec', '~>3.0'
  # KriKri uses Factory Girl to generate sample data
  gem 'factory_girl_rails', '~>4.4.0'
end

group :development, :test do
  gem 'rspec-core', '~>2.14.7'
  gem 'rspec-rails', '~>2.14.0'
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-byebug'
  gem 'pry-rails'
end

gem "factory_girl_rails", "~> 4.4.0", group: :development
gem "jettywrapper", "~> 1.8.3", group: :development
gem "devise", "~> 3.4.1"