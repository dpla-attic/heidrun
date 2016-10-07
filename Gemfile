source 'https://rubygems.org'

gem 'rails', '~> 4.1.11'
gem 'rake',  '~> 11.0.0'

gem 'krikri', '~> 0.14', '>=0.14.0'

gem 'sqlite3', '~> 1.3.11'
gem 'sass-rails', '~> 4.0.3'

# Gems used only for assets; not required by rails
# in production environments.
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'therubyracer', '~> 0.12.2',  platforms: :ruby

gem 'jquery-rails', '~> 3.1.4'
gem 'jquery-ui-rails', '~> 5.0.5'

group :development do
  gem 'spring', '~> 1.7.2'
  gem 'guard', '~> 1.8.3'
  gem 'guard-rspec', '~> 1.2.2'
end

group :test do
  gem 'codeclimate-test-reporter', '~> 0.6.0', require: false
end

group :development, :test do
  gem 'krikri-spec', github: 'dpla/krikri-spec', branch: 'develop'
  gem 'rspec-core',  '~> 3.4.4'
  gem 'rspec-rails', '~> 3.4.2'
  gem 'pry', '~> 0.10.4'
  gem 'pry-doc', '~> 0.9.0'
  gem 'pry-byebug', '~> 3.4.0'
  gem 'pry-rails', '~> 0.3.4'
  gem 'webmock', '~> 2.1.0', :require => false
end

gem 'factory_girl_rails', '~> 4.4.0', group: :development
gem 'jettywrapper', '~> 2.0.3', group: :development
gem 'devise', '3.4.1'
gem 'pg', '0.18.2'
gem 'unicorn', '4.8.3'

# Gems from krikri (@see KriKri/krikri.gemspec)
# In krikri, these gems are pinned to major or minor verions.
# Here, they are pinned to tiny versions so we can manage them more
# intentionally.

gem 'audumbla', '~> 0.2.1'
gem 'rest-client', '~> 2.0.0'
gem 'text', '~> 1.3'
gem 'jsonpath', '~> 0.5.8'
gem 'resque', '~> 1.26.0'
gem 'timecop', '~> 0.8.1'
