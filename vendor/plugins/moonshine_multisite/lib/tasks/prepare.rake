namespace :db do
  namespace :test do
    namespace :prepare do
      desc "prepares all test databases for all apps on the current stage"
      task :all => :environment do
        Rake::Task["environment"].invoke # don't know why the method above doesn't work
        Rake::Task["#{Common::SERVER}:test:#{Common::STAGE}:prepare"].invoke  
      end
    end
  end
end
