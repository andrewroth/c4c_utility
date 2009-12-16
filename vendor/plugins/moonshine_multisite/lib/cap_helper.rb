require "#{File.dirname(__FILE__)}/rake_helper.rb"

def pull_db(app, server, stage, remote_db, local_db)
  run_remote_rake "#{app}:dump:#{server}:#{stage}"
  local_dump_path = "tmp/#{remote_db}.sql".gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
  remote_dump_path = "#{current_path}/tmp/#{remote_db}.sql"
  download remote_dump_path+'.gz', local_dump_path+'.gz' 
  gunzip = Kernel.is_windows? ? File.join(File.dirname(__FILE__), '..', 'windows', 'gzip', 'gunzip.exe') : 'gunzip'
  execute_shell "#{gunzip} #{local_dump_path}.gz -f"
  load_dump local_dump_path, local_db
end

# helper task to run rake commands remotely
def run_remote_rake(rake_cmd)
  rake = fetch(:rake, "rake")
  rails_env = fetch(:rails_env, "production")
  run "cd #{current_path} && #{rake} RAILS_ENV=#{rails_env} #{rake_cmd.split(',').join(' ')}"
end
