set :application, "c4c_utility"
set :repository,  "git://github.com/andrewroth/c4c_utility.git"
set :scm, "git"
set :keep_releases, 3

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "pat.powertochange.org"
role :web, "pat.powertochange.org"
role :db,  "pat.powertochange.org", :primary => true

set :user, 'deploy'
set :deploy_to, "/var/www/c4c_utility.campusforchrist.org"

deploy.task :restart do
  # noop
end

def link_shared(p, o = {})
  if o[:overwrite]
    run "rm -Rf #{release_path}/#{p}"
  end

  run "ln -s #{shared_path}/#{p} #{release_path}/#{p}"
end

deploy.task :after_symlink do
  link_shared 'config/database.yml'
end

# Rake helper task.
def run_remote_rake(rake_cmd)
  rake = fetch(:rake, "rake")
  rails_env = fetch(:rake, "production")
  run "cd #{current_path} && #{rake} RAILS_ENV=#{rails_env} #{rake_cmd.split(',').join(' ')}"
end

namespace :deploy do
  namespace :p2c do
    namespace :klone do
      desc "runs p2c:clone:emu remotely"
      task :emu do
        run_remote_rake "p2c:clone:emu"
      end
      desc "runs p2c:clone:ciministry remotely"
      task :ciministry do
        run_remote_rake "p2c:clone:ciministry"
      end
      desc "runs p2c:clone:moose remotely"
      task :moose do
        run_remote_rake "p2c:clone:moose"
      end
      desc "runs p2c:clone:dev_pat remotely"
      task :dev_pat do
        run_remote_rake "p2c:clone:dev_pat"
      end
      desc "runs p2c:clone:all remotely"
      task :all do
        run_remote_rake "p2c:clone:all"
      end
    end
  end
end
