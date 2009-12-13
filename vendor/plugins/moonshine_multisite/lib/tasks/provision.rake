MOONSHINE_MULTISITE_ROOT = "#{File.dirname(__FILE__)}/../.."
RAILS_ROOT = "#{MOONSHINE_MULTISITE_ROOT}/../../.."
@multisite_config = YAML::load(File.read("#{MOONSHINE_MULTISITE_ROOT}/moonshine_multisite.yml"))

require 'capistrano/cli'

namespace :moonshine do
  namespace :multisite do
    namespace :provision do
      @multisite_config[:servers].each do |server, server_config|
        desc "Provision the #{server} server"
        task server do
          provision(server, server_config, false)
        end
      end
    end
  end 
end

# fix rake collisions with capistrano
undef :symlink
undef :ruby
undef :install

def run_shell(cmd)
  puts "[SH ] #{cmd}"
  system cmd
end

def run_shell_forked(cmd)
  puts "[SH ] #{cmd}"
  if fork.nil?
    exec(cmd)
    #Kernel.exit!
  end
  Process.wait
end

def new_cap(stage)
  # save password
  if @cap_config
    @password = @cap_config.fetch(:password)
  end
  @cap_config = Capistrano::Configuration.new
  Capistrano::Configuration.instance = @cap_config
  @cap_config.logger.level = Capistrano::Logger::TRACE
  if @password
    @cap_config.set(:password, @password)
  else
    @cap_config.set(:password) { Capistrano::CLI.password_prompt }
  end
  @cap_config.load "Capfile"
  @cap_config.load :file => "vendor/plugins/moonshine_multisite/recipes/explicit/multistage"
  @cap_config.find_and_execute_task(stage)
  @cap_config.find_and_execute_task("multistage:ensure")
end

def run_cap(stage, cmd)
  @cap_config.find_and_execute_task(cmd)
end

def cap_download_private(stage)
  puts "[DBG] Downloading private config files from secure repository"
  run_shell_forked "cap #{stage} moonshine:secure:download_private"
end

def cap_upload_certs(stage)
  puts "[DBG] Uploading private certs to server"
  #run_shell_forked "cap #{stage} moonshine:secure:upload_certs"
  run_cap stage, "moonshine:secure:upload_certs"
end

def provision(server, server_config, local)
  puts "[DBG] setup #{server} config #{server_config.inspect}"
  tmp_dir = "#{RAILS_ROOT}/tmp"
  for app, repo in @multisite_config[:apps]
    puts "========================  SITE  #{app.ljust(7, " ")} ========================"
    app_root = "#{tmp_dir}/#{app}"
    # checkout
    skipping = false
    unless File.directory? app_root
      run_shell "git clone #{repo} #{app_root}"
    end
    Dir.chdir app_root
    ENV['skip_hooks'] = 'true'
    # set up all apps on server
    first = true # first time deploy:setup should run
    @multisite_config[:stages].each do |stage|
      cap_stage = "#{server}/#{stage}"
      puts "------------------------ deploy #{stage.ljust(7, " ")} ------------------------"
      run_shell "git pull"
      # update and make sure this app is supposed to go on this server
      if !run_shell("git checkout #{server}.#{stage}")
        if !run_shell("git checkout -b #{server}.#{stage} origin/#{server}.#{stage}")
          puts "[WRN] Skipping installation of #{app} on #{server} since no #{server}.#{stage} branch found"
          next
        end
      end
      new_cap cap_stage
      # deploy
      server_moonshine_folder = "#{app_root}/config/deploy/#{server}"
      stage_moonshine_file = "#{server_moonshine_folder}/#{stage}_moonshine.yml"
      if File.directory?(server_moonshine_folder) && File.exists?(stage_moonshine_file)
=begin
        if first
          # each app needs to download the private assets directory, so that database.yml can be copied
          cap_download_private(cap_stage)
        end
        # initial setup 
        if (first && ENV['skip_setup'] != 'true') || (ENV['only_setup'] == 'true')
          unless local
            cap_upload_certs(cap_stage)
            run_cap cap_stage, "deploy:setup"
          else
            run_cap cap_stage, "deploy:setup"
          end
        else
          run_cap cap_stage, "moonshine:setup_directories"
        end
=end
        first = false
        #next if ENV['only_setup'] == 'true'
        # deploy to actually get everything there
        run_cap cap_stage, "deploy"
      else
        puts "[WRN] Skipping '#{stage}' stage (#{stage_moonshine_file} missing)"
      end
    end
  end
end
