def pull_db(task, prod_db, local_db)
  run_remote_rake "p2c:dump:#{task}"
  local_dump_path = "tmp/#{prod_db}.sql"
  remote_dump_path = "#{current_path}/tmp/#{prod_db}.sql"
  download remote_dump_path, local_dump_path
  load_dump local_dump_path, local_db
end

# helper task to run rake commands remotely
def run_remote_rake(rake_cmd)
  rake = fetch(:rake, "rake")
  rails_env = fetch(:rails_env, "production")
  run "cd #{current_path} && #{rake} RAILS_ENV=#{rails_env} #{rake_cmd.split(',').join(' ')}"
end
