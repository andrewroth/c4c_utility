require "#{File.dirname(__FILE__)}/../lib/multisite_helper.rb"
require "#{File.dirname(__FILE__)}/../lib/cap_helper.rb"

namespace :pull do
  multisite_config_hash[:apps].keys.each do |app|
    namespace app do
      utopian = utopian_db_name(fetch(:server_only, 'server'), app, fetch(:stage_only, 'stage'))
      legacy = legacy_db_name(fetch(:server_only, 'server'), app, fetch(:stage_only, 'stage'))
      db_name = utopian || legacy
      desc "dumps #{app} remotely, downloads it, and loads to utopian"
      task :utopian do
        pull_db app, fetch(:server_only, 'server'), fetch(:stage_only, 'stage'), db_name, utopian
      end
      desc "dumps #{app} remotely, downloads it, and loads it legacy"
      task :legacy do
        pull_db app, fetch(:server_only, 'server'), fetch(:stage_only, 'stage'), db_name, legacy
      end
    end

    namespace :all do
      desc "pulls all remote apps and stages and sets them to utopian names locally"
      task :utopian do
        multisite_config_hash[:apps].keys.each do |app|
          multisite_config_hash[:stages].each do |stage|
            find_and_execute_task "#{fetch(:server_only)}/#{stage}"
            find_and_execute_task "pull:#{app}:utopian"
          end
        end
      end

      desc "pulls all remote apps and stages and sets them to legacy names locally"
      task :legacy do
        multisite_config_hash[:apps].keys.each do |app|
          multisite_config_hash[:stages].each do |stage|
            find_and_execute_task "#{fetch(:server_only)}/#{stage}"
            find_and_execute_task "pull:#{app}:legacy"
          end
        end
      end
    end
  end
end

namespace :klone do
  multisite_config_hash[:apps].keys.each do |app|
    namespace app do
      multisite_config_hash[:stages].each do |stage|
        next if stage == @master_stage
        utopian = utopian_db_name(fetch(:server_only, 'server'), app, fetch(:stage_only, 'stage'))
        legacy = legacy_db_name(fetch(:server_only, 'server'), app, fetch(:stage_only, 'stage'))
        namespace stage do
          desc "runs rake #{app}:klone:<server>:#{stage}"
          task :remotely do
            run_rake_remotely "#{app}:klone:#{fetch(:server)}:#{stage}"
          end
          desc "runs rake #{app}:klone:<server>:#{stage}:legacy"
          task :legacy_remotely do
            run_rake_remotely "#{app}:klone:#{fetch(:server)}:#{stage}:legacy"
          end
        end
      end
    end
  end
end
