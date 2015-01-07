# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

desc "Start Jetty and run all specs"
task :ci => ['jetty:clean'] do
  Rake::Task['jetty:config'].invoke

  Jettywrapper.wrap(quiet: true, jetty_port: 8983, :startup_wait => 30) do
    Rake::Task["spec"].invoke
  end
end

desc "Run all specs in spec directory (excluding plugin specs)"
task :default => :ci