Dir[Rails.root.join('app/mappings/**/*.rb')].each { |f| require f }
