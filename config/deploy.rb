set :application, "c4c_utility"
set :repository,  "git://github.com/andrewroth/c4c_utility.git"
set :scm, "git"

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
