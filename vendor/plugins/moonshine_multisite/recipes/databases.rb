require "#{File.dirname(__FILE__)}/../lib/multisite_helper.rb"
require "#{File.dirname(__FILE__)}/../lib/cap_helper.rb"

namespace :pull do
  multisite_config_hash[:apps].keys.each do |app|
    namespace app do
      task :set_db_names do
        puts "[DBG] set_db_names server_only=#{fetch(:server_only)} stage=#{fetch(:stage_only)}"
        set(:utopian, utopian_db_name(fetch(:server_only), app, fetch(:stage_only)))
        set(:legacy, legacy_db_name(fetch(:server_only), app, fetch(:stage_only)))
        #puts "[DBG] set_db_names utopian=#{fetch(:utopian)} legacy=#{fetch(:legacy)} app=#{app}"
        set(:remote_db, fetch(:legacy) || fetch(:utopian))
      end
      #utopian = utopian_db_name(fetch(:server_only), app, fetch(:stage_only))
      #legacy = legacy_db_name(fetch(:server_only), app, fetch(:stage_only))
      #db_name = legacy || utopian
      desc "dumps #{app} remotely, downloads it, and loads to utopian"
      task :utopian do
        set_db_names
        pull_db app, fetch(:server_only), fetch(:stage_only), fetch(:remote_db), fetch(:utopian)
      end
      desc "dumps #{app} remotely, downloads it, and loads it legacy"
      task :legacy do
        set_db_names
        pull_db app, fetch(:server_only), fetch(:stage_only), fetch(:remote_db), fetch(:legacy)
      end

      namespace :to do
        multisite_config_hash[:servers].keys.each do |to_server|
          desc "dumps #{app} remotely, downloads it, and loads it to the database with utopian #{to_server} name"
          task to_server do
            find_and_execute_task "pull:#{app}:set_db_names"
            to_name = utopian_db_name(to_server, app, fetch(:stage_only))
            pull_db app, fetch(:server_only), fetch(:stage_only), fetch(:remote_db), to_name
          end
        end
      end
    end

    namespace :all do
      desc "pulls all remote apps and stages and sets them to utopian names locally"
      task :utopian do
        multisite_config_hash[:apps].keys.each do |app|
          multisite_config_hash[:stages].each do |stage|
            find_and_execute_task "#{fetch(:server_only)}/#{stage}"
            find_and_execute_task "multistage:ensure"
            find_and_execute_task "pull:#{app}:utopian"
          end
        end
      end

      desc "pulls all remote apps and stages and sets them to legacy names locally"
      task :legacy do
        multisite_config_hash[:apps].keys.each do |app|
          multisite_config_hash[:stages].each do |stage|
            find_and_execute_task "#{fetch(:server_only)}/#{stage}"
            find_and_execute_task "multistage:ensure"
            find_and_execute_task "pull:#{app}:legacy"
          end
        end
      end

      namespace :to do
        multisite_config_hash[:servers].keys.each do |to_server|
          namespace to_server do
            desc "pulls all remote apps and stages and loads them to utopian #{to_server} names locally"
            task :utopian do
              multisite_config_hash[:apps].keys.each do |app|
                multisite_config_hash[:stages].each do |stage|
                  find_and_execute_task "#{fetch(:server_only)}/#{stage}"
                  find_and_execute_task "multistage:ensure"
                  find_and_execute_task "pull:#{app}:to:#{to_server}"
                end
              end
            end
          end
        end
      end
    end

    namespace :all do
      desc "pulls all apps off the server and uses the utopian naming locally"
      task :utopian do
        multisite_config_hash[:apps].keys.each do |app|
          multisite_config_hash[:stages].each do |stage|
            set(:stage_only, stage)
            find_and_execute_task "pull:#{app}:utopian"
          end
        end
      end
      desc "pulls all apps off the server and uses the legacy naming locally"
      task :legacy do
        multisite_config_hash[:apps].keys.each do |app|
          multisite_config_hash[:stages].each do |stage|
            set(:stage_only, stage)
            find_and_execute_task "pull:#{app}:legacy"
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
end
