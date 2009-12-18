require "#{File.dirname(__FILE__)}/../lib/multisite_helper.rb"
require "#{File.dirname(__FILE__)}/../lib/cap_helper.rb"

namespace :pull do
  multisite_config_hash[:apps].keys.each do |app|
    task :set_remote_db do
      debug "[DBG] set_remote_db server_only=#{fetch(:server_only)} stage=#{fetch(:stage_only)}"
      set(:utopian, utopian_db_name(fetch(:server_only), fetch(:app), fetch(:stage_only)))
      set(:legacy, legacy_db_name(fetch(:server_only), fetch(:app), fetch(:stage_only)))
      set(:remote_db, fetch(:legacy) || fetch(:utopian))
      debug "[DBG] set_remote_db utopian=#{fetch(:utopian)} legacy=#{fetch(:legacy)} app=#{app}"
    end
    task :set_local_db do
      debug "[DBG] set_local_db app=#{app}"
      local_server_only = fetch(:local_server_only, fetch(:server_only))
      local_stage_only = fetch(:local_stage_only, fetch(:stage_only))
      set(:local_utopian, utopian_db_name(local_server_only, fetch(:app), local_stage_only))
      set(:local_legacy, legacy_db_name(local_server_only, fetch(:app), local_stage_only))
      if fetch(:utopian_override, false)
        set(:local_db, fetch(:local_utopian))
      else
        set(:local_db, fetch(:local_legacy) || fetch(:local_utopian))
      end
    end

    namespace app do
      desc "dumps #{app} remotely, downloads it, and loads locally (all if stage not given)"
      task :default do
        if fetch(:stage_only, nil)
          set(:app, app)
          set_remote_db
          set_local_db
          pull_db app, fetch(:server_only), fetch(:stage_only), fetch(:remote_db), fetch(:local_db)
        else
          find_and_execute_task "pull:#{app}:all"
        end
      end

      namespace :to do
        multisite_config_hash[:servers].keys.each do |to_server|
          desc "dumps #{app} remotely, downloads it, and loads locally, using #{to_server} naming (leave stage out to pull all stages)"
          namespace to_server do
            task :default do
              if fetch(:stage_only, nil)
                set(:app, app)
                set(:local_server_only, to_server)
                set_remote_db
                set_local_db
                pull_db app, fetch(:server_only), fetch(:stage_only), fetch(:remote_db), fetch(:local_db)
              else
                find_and_execute_task "pull:#{app}:to:#{to_server}:all"
              end
            end

            task :utopian do
              set(:utopian_override, true)
              default
            end

            task :all do # all stages
              set(:app, app)
              set(:local_server_only, to_server)
              multisite_config_hash[:stages].each do |stage|
                find_and_execute_task "#{fetch(:server_only)}/#{stage}"
                find_and_execute_task "multistage:ensure"
                find_and_execute_task "pull:#{app}:to:#{to_server}"
              end
            end
          end
        end
      end

      task :all do
        multisite_config_hash[:stages].each do |stage|
          find_and_execute_task "#{fetch(:server_only)}/#{stage}"
          find_and_execute_task "multistage:ensure"
          find_and_execute_task "pull:#{app}"
        end
      end
    end
  end

  namespace :all do # all apps
    desc "pulls all apps and stages"
    task :default do
      if fetch(:stage_only, nil)
        puts "pull:all should not have a stage specified"
        exit(0)
      end
      multisite_config_hash[:apps].keys.each do |app|
        find_and_execute_task "pull:#{app}"
      end
    end

    task :utopian do
      set(:utopian_override, true)
      default
    end

    namespace :to do
      multisite_config_hash[:servers].keys.each do |to_server|
        namespace to_server do
          task :default do
            desc "pulls all apps and stages using #{to_server} naming"
            if fetch(:stage_only, nil)
              puts "pull:all:to:#{to_server} should not have a stage specified"
              exit(0)
            end
            multisite_config_hash[:apps].keys.each do |app|
              find_and_execute_task "pull:#{app}:to:#{to_server}"
            end
          end
          task :utopian do
            set(:utopian_override, true)
            default
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
        #utopian = utopian_db_name(fetch(:server_only, 'server'), app, fetch(:stage_only, 'stage'))
        #legacy = legacy_db_name(fetch(:server_only, 'server'), app, fetch(:stage_only, 'stage'))
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
